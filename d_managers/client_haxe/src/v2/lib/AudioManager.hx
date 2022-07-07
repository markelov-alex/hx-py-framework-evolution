package v2.lib;

import haxe.Exception;
import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import v1.lib.AudioManager in AudioManager1;
import v1.lib.Log;
import v1.lib.ResourceManager;
import v1.lib.Signal;

/**
 * AudioManager.
 * 
 * Terms:
 * Sounds can play simultaneously, overlapping each other.
 * Music can play only one at a time.
 * Audio is an abstraction for both sounds and music.
 * 
 * Changes:
 *  - as class can not be extended, convert to singleton,
 *  - add sound/musicVolume,
 *  - add volume and pan for each track,
 *  - add playlist support.
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
			instance = new AudioManager();
		}
		return instance;
	}

	// Note: Use AudioManager1.isSound/MusicOn to fix Sound/MusicToggleButton
	@:isVar
	public var isSoundOn(get, set):Bool = true;
	public function get_isSoundOn():Bool
	{
		return AudioManager1.isSoundOn;
	}
	public function set_isSoundOn(value:Bool):Bool
	{
		if (AudioManager1.isSoundOn != value)
		{
			AudioManager1.isSoundOn = value;
			refreshSoundOn();
			// Dispatch
			toggleSoundSignal.dispatch(value);
		}
		return value;
	}

	@:isVar
	public var isMusicOn(get, set):Bool = true;
	public function get_isMusicOn():Bool
	{
		return AudioManager1.isMusicOn;
	}
	public function set_isMusicOn(value:Bool):Bool
	{
		if (AudioManager1.isMusicOn != value)
		{
			AudioManager1.isMusicOn = value;
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
		}
		return value;
	}

	private var currentSounds:Array<SoundChannel> = [];
	// If new screen shows and starts new music, and only then old screen hides and 
	// stops its music, then it should be stopped by name to do not accidently stop 
	// the new music. So, technically it's possible that more than one music existing 
	// at a time and thus a Map is needed.
	private var musicByName:Map<String, SoundChannel> = new Map();

	// As playMusic() now uses also volume and pan args it'd be better to create new 
	// object type (Track) rather than adding new properties.
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
		if (instance != null)
		{
			throw new Exception("Singleton class can have only one instance!");
		}
		instance = this;
		
		// Temp: Hack to do not override Sound/MusicToggleButton for using new AudioManager
		AudioManager1.toggleSoundSignal.add(function (value) {refreshSoundOn();});
		AudioManager1.toggleMusicSignal.add(function (value) {refreshMusicOn();});
	}

	// Methods

	public function playSound(name:String, volume:Float=1, pan:Float=0):SoundChannel
	{
		if (name == null || !isSoundOn)
		{
			return null;
		}
		var assetName = getAssetName(name);
		var sound = ResourceManager.getSound(assetName);
		if (sound == null)
		{
			return null;
		}
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
	public function playMusic(name:Dynamic, isLoop=true, startTime:Float=0, 
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
			if (playlist == null || playlist.name != name)
			{
				// Reset current track for new playlist
				playlistIndex = 0;
			}
			if (playlistIndex >= names.length)
			{
				playlistIndex = 0;
			}
			Log.debug('Play playlist: $name');
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
	private function _playMusic(name:Dynamic, isLoop=true, startTime:Float=0,
							  volume:Float=1, pan:Float=0):SoundChannel
	{
		// Set before all to play after isMusicOn=true
		currentMusic = {name: name, isLoop: isLoop, startTime: startTime, volume: volume, pan: pan};
		if (!isMusicOn)
		{
			return null;
		}

		// Get sound from assets
		var assetName = getAssetName(name);
		var sound = ResourceManager.getMusic(assetName);
//		ResourceManager.getMusic(assetName, function (sound:Sound) {
		if (sound == null)
		{
			return null;
		}

		// Play
		var st = new SoundTransform(musicVolume * volume, pan);
		Log.debug('Play music $name from: $startTime with volume: ${st.volume} = $musicVolume * $volume');
		var soundChannel = sound.play(startTime, isLoop ? musicLoopCount : 0, st);
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

	public function stopMusic(name:String=null):SoundChannel
	{
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
		if (currentMusic != null && soundChannel != null)
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
				playMusic(currentMusic.name, currentMusic.isLoop, currentMusic.startTime, 
					currentMusic.volume, currentMusic.pan);
			}
		}
		else
		{
			// Doesn't reset currentMusic
			_stopMusic();
		}
	}

	private function getAssetName(name:String):String
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
