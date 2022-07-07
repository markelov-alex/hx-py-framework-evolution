package v3.lib;

import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import v1.lib.Log;
import v1.lib.Signal;
import v3.lib.ArrayUtil;

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
 * Changes:
 *  - some changes for v4, not affecting the logic,
 *  - make isLoop=false by default.
 */
class AudioManager
{
	// Settings

	public var namePrefix = "assets/audio/";
	#if flash
	public var nameExt = ".mp3";
	#else
	public var nameExt = ".ogg";
	#end
	// Loop count for music if played with isLoop=true
	public var musicLoopCount = 1000;

	// State
	
	public static var instance:AudioManager;
	public static function getInstance():AudioManager
	{
		if (instance == null)
		{
			// Previous way
			//instance = new AudioManager();
			// With IoC
			instance = IoC.getInstance().getSingleton(AudioManager);
			// Or same (as singleton set to IoC from manager's constructor):
			//instance = IoC.getInstance().create(AudioManager);
		}
		return instance;
		// Or even simplier
		//return IoC.getInstance().getSingleton(AudioManager);
	}
	
	private var resourceManager = ResourceManager.getInstance();

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
			Log.debug("Music volume: " + value + ' delta: $dv');
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
		// Throws exception if more than 1 instance
		IoC.getInstance().setSingleton(AudioManager, this);
	}

	// Methods

	public function playSound(name:String, volume:Float=1, pan:Float=0):SoundChannel
	{
		if (name == null || !isSoundOn)
		{
			return null;
		}
		// Get
		var assetName = getAssetName(name);
		var sound = resourceManager.getSound(assetName);
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
	public function playMusic(name:Dynamic, isLoop=false, startTime:Float=0, 
							  volume:Float=1, pan:Float=0):SoundChannel
	{
		if (name == null)
		{
			return null;
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
	private function _playMusic(name:Dynamic, isLoop=false, startTime:Float=0,
								volume:Float=1, pan:Float=0):SoundChannel
	{
		pan = pan < -1 ? -1 : (pan > 1 ? 1 : pan);
		
		// Set before all to play after isMusicOn=true
		currentMusic = {name: name, isLoop: isLoop, startTime: startTime, volume: volume, pan: pan};
		if (!isMusicOn)
		{
			return null;
		}

		// Get sound from assets
		var assetName = getAssetName(name, true);
		var sound = resourceManager.getMusic(assetName);
//		resourceManager.getMusic(assetName, function (sound:Sound) {
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

	private function refreshSoundOn():Void
	{
		if (!isSoundOn)
		{
			stopAllSounds();
		}
	}

	private function refreshMusicOn():Void
	{
		if (isMusicOn)
		{
			if (currentMusic != null)
			{
				_playMusic(currentMusic.name, currentMusic.isLoop, currentMusic.startTime, 
					currentMusic.volume, currentMusic.pan);
			}
		}
		else
		{
			// Doesn't reset currentMusic
			_stopMusic();
		}
	}

	private function checkCurrentMusicLoop():Bool
	{
		if (currentMusic != null && currentMusic.isLoop)
		{
			Log.debug('Stop looped music: ${currentMusic.name}');
			_playMusic(currentMusic.name, currentMusic.isLoop, 0,
				currentMusic.volume, currentMusic.pan);
			return true;
		}
		return false;
	}

	// Add isMusic for v4
	private function getAssetName(name:String, isMusic=false):String
	{
		// Add dir path to all (namePrefix), and file extension if absent (nameExt).
		return namePrefix + name + (name.indexOf(".") == -1 ? nameExt : "");
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
