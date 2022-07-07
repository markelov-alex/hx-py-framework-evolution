package v1.framework;

import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.net.SharedObject;
import v1.framework.util.ArrayUtil;
import v1.framework.util.Log;
import v1.framework.util.Signal;
/**
 * AudioManager.
 * 
 * Terms:
 * Sounds can play simultaneously, overlapping each other.
 * Music can play only one at a time.
 * Audio is an abstraction for both sounds and music.
 * 
 * Sound can not be looped or continued (started) from some other 
 * position than beginning. Playlist are also not available for sounds.
 * 
 * As we have not special classes for sounds and music, to 
 * preconfig them external audio config file is used (JSON and YAML).
 */
class AudioManager extends Base
{
	// Settings

	public var defaultAssetName = "audio.yml";
	private var defaultConfig:Track = {
		name: null, isLoop: false, startTime: 0, volume: 1, pan: 0,
	};

	public var namePrefix = "assets/audio/";
	#if flash
	public var nameExt = ".mp3";
	#else
	public var nameExt = ".ogg";
	#end
	// Loop count for music if played with isLoop=true
	public var musicLoopCount = 1000;

	// State
	
	private var resource:ResourceManager;
	private var shared:SharedObject = SharedObject.getLocal("managers");

	private var soundConfigByName = new Map<String, Track>();
	private var musicConfigByName = new Map<String, Track>();

	public var isSoundOn(default, set):Bool = true;
	public function set_isSoundOn(value:Bool):Bool
	{
		if (isSoundOn != value)
		{
			isSoundOn = value;
			refreshSoundOn();
			// Dispatch
			toggleSoundSignal.dispatch(value);
		}
		return value;
	}

	public var isMusicOn(default, set):Bool = true;
	public function set_isMusicOn(value:Bool):Bool
	{
		if (isMusicOn != value)
		{
			isMusicOn = value;
			refreshMusicOn();
			// Dispatch
			toggleMusicSignal.dispatch(value);
		}
		return value;
	}

	public var soundVolume(default, set):Float = 1;
	public function set_soundVolume(value:Float):Float
	{
		// For openfl (flash) -value is same as value
		value = value < 0 ? 0 : value;
		if (soundVolume != value)
		{
			var dv = value - soundVolume;
			soundVolume = value;
			Log.debug("Sound volume: " + value);
			for (sc in currentSounds)
			{
				// (Reuse existing soundTransform)
				var st = sc.soundTransform;
				st.volume += dv;
				sc.soundTransform = st;
			}
			shared.data.soundVolume = value;
		}
		return value;
	}

	public var musicVolume(default, set):Float = 1;
	public function set_musicVolume(value:Float):Float
	{
		// For openfl (flash) -value is same as value
		value = value < 0 ? 0 : value;
		if (musicVolume != value)
		{
			var dv = value - musicVolume;
			musicVolume = value;
			Log.debug("Music volume: " + value+ '$dv');
			for (name => sc in musicByName)
			{
				// (Reuse existing soundTransform)
				var st = sc.soundTransform;
				if (currentMusic != null && currentMusic.name == name)
				{
					st.volume = musicVolume * currentMusic.volume;
				}
				else
				{
					// Not necessary as only currentMusic does matter
					st.volume += dv;
				}
				sc.soundTransform = st;
			}
			shared.data.musicVolume = value;
		}
		return value;
	}

	private var currentSounds:Array<SoundChannel> = [];
	// If new screen shows and starts new music, and only then old screen hides and 
	// stops its music, then it should be stopped by name to do not accidently stop 
	// the new music. So, technically it's possible that more than one music existing 
	// at a time and thus a Map is needed.
	private var musicByName:Map<String, SoundChannel> = new Map();

	public var currentMusic(default, null):Track;
	private var playlist:Track;
	private var playlistIndex:Int = 0;

	// Signals

	public var toggleSoundSignal(default, null) = new Signal<Bool>();
	public var toggleMusicSignal(default, null) = new Signal<Bool>();
	public var soundVolumeChangeSignal(default, null) = new Signal<Float>();
	public var musicVolumeChangeSignal(default, null) = new Signal<Float>();

	// Init

	public function new()
	{
		super();

		//shared.clear();
		if (shared.data.isMusicOn != null)
		{
			isSoundOn = shared.data.isSoundOn;
			isMusicOn = shared.data.isMusicOn;
			soundVolume = shared.data.soundVolume;
			musicVolume = shared.data.musicVolume;
		}
		else
		{
			shared.data.isSoundOn = isSoundOn;
			shared.data.isMusicOn = isMusicOn;
			shared.data.soundVolume = soundVolume;
			shared.data.musicVolume = musicVolume;
		}
	}

	override private function init():Void
	{
		super.init();

		// Throws exception if more than 1 instance
		ioc.setSingleton(AudioManager, this);
		resource = ioc.getSingleton(ResourceManager);
	}

	override public function dispose():Void
	{
		toggleSoundSignal.dispose();
		toggleMusicSignal.dispose();
		soundVolumeChangeSignal.dispose();
		musicVolumeChangeSignal.dispose();
		
		stopMusic();
		stopAllSounds();
		
		resource = null;
		
		super.dispose();
	}

	public function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}

		// Get/load data
		Log.debug('Load: $assetName');
		var data = resource.getData(assetName);
		if (data == null)
		{
			return;
		}

		// Set up manager and convert dict Objects -> lookup Maps
		for (key in Reflect.fields(data))
		{
			// Set up manager
			if (Reflect.hasField(this, key))
			{
				Reflect.setProperty(this, key, Reflect.getProperty(data, key));
			}
		}
		// Update track configs
		updateConfig(soundConfigByName, data.sound);
		updateConfig(musicConfigByName, data.music);
	}

	private function updateConfig(configByName:Map<String, Track>, data:Dynamic):Void
	{
		for (name in Reflect.fields(data))
		{
			// Get current or create default
			var config:Track = configByName[name];
			if (config == null)
			{
				// (Create with default values)
				config = configByName[name] = {
					name: name,
					isLoop: defaultConfig.isLoop,
					startTime: defaultConfig.startTime,
					volume: defaultConfig.volume,
					pan: defaultConfig.pan,
				};
			}

			// Update with loaded data
			var item = Reflect.getProperty(data, name);
			for (key in Reflect.fields(defaultConfig))
			{
				if (Reflect.hasField(item, key))
				{
					Reflect.setProperty(config, key, Reflect.getProperty(item, key));
				}
			}
		}
	}

	// Methods

	public function playSound(name:String, volume:Float=1, pan:Float=0):SoundChannel
	{
		var config:Track = soundConfigByName[name];
		if (config != null)
		{
			//-name = config.name;
			//Log.debug('(Sound with config - ' +
			//	'volume: ${volume * config.volume} = $volume * ${config.volume} ' +
			//	'pan: ${pan + config.pan} = $pan + ${config.pan})');
			volume = volume * config.volume;
			pan = pan + config.pan;
		}
		
		if (name == null || !isSoundOn)
		{
			return null;
		}
		// Get
		var assetName = getAssetName(name);
		var sound = resource.getSound(assetName);
		if (sound == null)
		{
			return null;
		}
		pan = pan < -1 ? -1 : (pan > 1 ? 1 : pan);
		// Play
		var soundChannel = sound.play(0, 0, new SoundTransform(soundVolume * volume, pan));
		currentSounds.push(soundChannel);
		// Listeners
		soundChannel.addEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
		return soundChannel;
	}

	public function stopAllSounds():Void
	{
		for (sc in currentSounds)
		{
			// Listeners
			sc.removeEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
			sc.stop();
		}
		currentSounds = [];
	}

	/**
	 * Play music track (name:String) or playlist (name:Array<String>).
	 */
	public function playMusic(name:Dynamic, isLoop=false, startTime:Float=0, volume:Float=1, pan:Float=0):SoundChannel
	{
		// Apply config for playlist only
		var config:Track = musicConfigByName[name];
		if (config != null && Std.isOfType(config.name, Array))
		{
			name = config.name; // Only for playlist
			isLoop = isLoop || config.isLoop;
			startTime = startTime > 0 ? startTime : config.startTime;
			volume = volume * config.volume;
			pan = pan + config.pan;
		}

		// Stop previous (even if same, because isLoop can be different)
		var soundChannel = currentMusic != null ? _stopMusic(currentMusic.name) : null;
		var isPlaylist = Std.isOfType(name, Array);
		if (isPlaylist)
		{
			var names:Array<String> = cast name;
			if (names.length <= 0)
			{
				// Empty playlist
				return null;
			}
			if (playlist == null || !ArrayUtil.equal(cast playlist.name, names))
			{
				// Reset current track for new playlist
				playlistIndex = 0;
			}
			if (playlistIndex >= names.length)
			{
				playlistIndex = 0;
			}
			Log.debug('Play playlist: $name with volume: $volume and pan: $pan');
			playlist = {name: name, isLoop: isLoop, startTime: startTime, volume: volume, pan: pan};
			// Select track
			name = names[playlistIndex];
			isLoop = false;
		}
		else
		{
			playlist = null;
		}
		// Continue from current position if same
		var isSame = currentMusic != null && currentMusic.name == name;
		if (isSame)
		{
			// Note: currentMusic.startTime=soundChannel.position set in _stopMusic()
			startTime = currentMusic.startTime;
		}
		return _playMusic(name, isLoop, startTime, volume, pan);
	}

	/**
	 * Play a track.
	 */
	public function _playMusic(name:Dynamic, isLoop=false, startTime:Float=0, 
							   volume:Float=1, pan:Float=0, isPlayNew=true):SoundChannel
	{
		// Apply config for track
		var config:Track = musicConfigByName[name];
		// If isPlayNew=true, then config can be applied. 
		// isPlayNew=false on isMusicOn just set to true or same tracked makes another loop.
		if (isPlayNew && config != null)
		{
			//Log.debug('(Music with config - ' + 
			//	  'volume: ${volume * config.volume} = $volume * ${config.volume} ' + 
			//	  'pan: ${pan + config.pan} = $pan + ${config.pan})');
			// (Real name to be resolved in getAssetName())
			//-name = config.name;
			isLoop = isLoop || config.isLoop;
			startTime = startTime > 0 ? startTime : config.startTime;
			volume = volume * config.volume;
			pan = pan + config.pan;
		}

		pan = pan < -1 ? -1 : (pan > 1 ? 1 : pan);

		// Set before all to play after isMusicOn=true
		currentMusic = {name: name, isLoop: isLoop, startTime: startTime, 
						volume: volume, pan: pan};
		if (!isMusicOn)
		{
			return null;
		}

		// Get sound from assets
		var assetName = getAssetName(name, true);
		var sound = resource.getMusic(assetName);
//		resource.getMusic(assetName, function (sound:Sound) {
		if (sound == null)
		{
			return null;
		}

		// Play
		var st = new SoundTransform(musicVolume * volume, pan);
		var loops = isLoop && startTime == 0 ? musicLoopCount : 0;
		Log.debug('Play music $name from: $startTime with volume: ${st.volume} = $musicVolume * $volume and pan: $pan, ' +
			'isLoop: $isLoop loops: $loops');
		// (If startTime > 0 and loops > 0, then each loop also starts from startTime. 
		// To fix that, we use own looping combined. (Test on short track, turning music on/off.))
		var soundChannel = sound.play(startTime, loops, st);
		if (soundChannel == null)
		{
			// For example, if startTime is greater than sound length
			return null;
		}
		musicByName[name] = soundChannel;
		// Listeners
		soundChannel.addEventListener(Event.SOUND_COMPLETE, music_soundCompleteHandler);
		return soundChannel;
//		});
		return null;
	}

	/**
	 * Stop playlist specifying name as same list as was given for playMusic().
	 */
	public function stopMusic(name:Dynamic=null):SoundChannel
	{
		// Stop playlist by its real name - as list of tracks
		var config:Track = musicConfigByName[name];
		if (config != null && Std.isOfType(config.name, Array))
		{
			name = config.name;
		}

		// Stop playlist
		if (playlist != null && Std.isOfType(name, Array) && ArrayUtil.equal(playlist.name, name))
		{
			// To stop current track in the playlist
			name = playlist.name[playlistIndex];
			playlist = null;
		}

		// Stop track
		var soundChannel = _stopMusic(name);
		// (Should be after musicByName.remove() to prevent infinite recursion)
		if (currentMusic != null && name == currentMusic.name)
		{
			currentMusic = null;
		}
		return soundChannel;
	}

	private function _stopMusic(name:String=null):SoundChannel
	{
		if (name == null && currentMusic != null)
		{
			name = currentMusic.name;
		}
		var soundChannel = musicByName[name];
		if (soundChannel == null)
		{
			return null;
		}
		musicByName.remove(name);
		// Save params to restore (on isMusicOn=true)
		if (currentMusic != null && soundChannel != null && currentMusic.name == name)
		{
			currentMusic.startTime = soundChannel.position;
		}
		// Listeners
		soundChannel.removeEventListener(Event.SOUND_COMPLETE, music_soundCompleteHandler);
		soundChannel.stop();
		return soundChannel;
	}

	private function getAssetName(name:String, isMusic=false):String
	{
		// Get real name
		var configByName = isMusic ? musicConfigByName : soundConfigByName;
		var config:Track = configByName[name];
		if (config != null && Std.isOfType(config.name, String))
		{
			name = config.name;
		}

		// Build prefix to add path if needed
		var isRootName = name.indexOf("/") == 0 || name.indexOf("\\") == 0;
		var prefix = isRootName ? "" : namePrefix;
		var prefixLastSym = prefix != "" ? prefix.charAt(prefix.length - 1) : null;
		if (prefixLastSym != null && prefixLastSym != "/" && prefixLastSym != "\\")
		{
			// Add slash to end if absent
			prefix += "/";
		}
		if (isRootName)
		{
			// Remove first slash
			name = name.substring(1);
		}
		// Build postfix to add extension if needed
		var postfix = name.indexOf(".") == -1 ? nameExt : "";
		// Add
		return prefix + name + postfix;
	}

	private function refreshSoundOn():Void
	{
		if (!isSoundOn)
		{
			stopAllSounds();
		}
		
		shared.data.isSoundOn = isSoundOn;
	}

	private function refreshMusicOn():Void
	{
		if (isMusicOn)
		{
			if (currentMusic != null)
			{
				_playMusic(currentMusic.name, currentMusic.isLoop, currentMusic.startTime,
				currentMusic.volume, currentMusic.pan, false);
			}
		}
		else
		{
			// Doesn't reset currentMusic
			_stopMusic();
		}

		shared.data.isMusicOn = isMusicOn;
	}

	private function checkCurrentMusicLoop():Bool
	{
		if (currentMusic != null && currentMusic.isLoop)
		{
			Log.debug('Stop looped music: ${currentMusic.name}');
			_playMusic(currentMusic.name, currentMusic.isLoop, 0,
				currentMusic.volume, currentMusic.pan, false);
			return true;
		}
		return false;
	}

	// Handlers

	private function sound_soundCompleteHandler(event:Event):Void
	{
		// (Always not null)
		var soundChannel = cast(event.currentTarget, SoundChannel);
		// Listeners
		soundChannel.removeEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
		currentSounds.remove(soundChannel);
	}

	private function music_soundCompleteHandler(event:Event):Void
	{
		// Looping current track (can be stopped on loops out or 
		// loops were set to 0 after music just turned on)
		if (checkCurrentMusicLoop())
		{
			return;
		}

		// Clear currentMusic
		stopMusic();

		// Process playlist (next track or finish)
		if (playlist != null)
		{
			// Next track
			playlistIndex++;
			// Check playlist ends
			if (playlistIndex >= playlist.name.length)
			{
				if (playlist.isLoop)
				{
					// Start again
					playlistIndex = 0;
				}
				else
				{
					// Stop playlist
					playlist = null;
					return;
				}
			}
			var name = playlist.name[playlistIndex];
			_playMusic(name, false, 0, playlist.volume, playlist.pan);
		}
	}
}

typedef Track = {
	var name:Dynamic;
	var isLoop:Bool;
	var startTime:Float;
	var volume:Float;
	var pan:Float;
}
