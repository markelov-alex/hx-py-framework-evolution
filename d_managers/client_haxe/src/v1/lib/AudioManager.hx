package v1.lib;

import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;

/**
 * AudioManager.
 * 
 * Terms:
 * Sounds can play simultaneously, overlapping each other.
 * Music can play only one at a time.
 * Audio is an abstraction for both sounds and music.
 */
class AudioManager
{
	// Settings
	
	public static var namePrefix = "assets/audio/";
	#if flash
	public static var nameExt = ".mp3";
	#else
	public static var nameExt = ".ogg";
	#end
	// Loop count for music if played with isLoop=true
	public static var musicLoopCount = 1000;

	// State
	
//	public static var isAudioOn(default, set):Bool = true;
//	public static function set_isAudioOn(value:Bool):Bool
//	{
//		if (isAudioOn != value)
//		{
//			isAudioOn = value;
//			refreshSound();
//			refreshMusic();
//			// Dispatch
//			toggleAudioSignal.dispatch(value);
//			toggleSoundSignal.dispatch(value);
//			toggleMusicSignal.dispatch(value);
//		}
//		return value;
//	}

//	@:isVar
	public static var isSoundOn(default, set):Bool = true;
//	public static function get_isSoundOn():Bool
//	{
//		return isAudioOn && isSoundOn;
//	}
	public static function set_isSoundOn(value:Bool):Bool
	{
		if (isSoundOn != value)
		{
			isSoundOn = value;
			refreshSound();
			// Dispatch
			toggleSoundSignal.dispatch(value);
		}
		return value;
	}
	
//	@:isVar
	public static var isMusicOn(default, set):Bool = true;
//	public static function get_isMusicOn():Bool
//	{
//		return isAudioOn && isMusicOn;
//	}
	public static function set_isMusicOn(value:Bool):Bool
	{
		if (isMusicOn != value)
		{
			isMusicOn = value;
			refreshMusic();
			// Dispatch
			toggleMusicSignal.dispatch(value);
		}
		return value;
	}

	private static var currentSounds:Array<SoundChannel> = [];
	// If new screen shows and starts new music, and only then old screen hides and 
	// stops its music, then it should be stopped by name to do not accidently stop 
	// the new music.
	private static var musicByName:Map<String, SoundChannel> = new Map();
	
	public static var currentMusic(default, set):String;
	public static function set_currentMusic(value:String):String
	{
		if (currentMusic != value)
		{
			// Stop previous
			if (currentMusic != null)
			{
				stopMusic(currentMusic);
			}
			// Set
			currentMusic = value;
		}
		return value;
	}
	private static var lastStoppedMusic:String;
	private static var isLoopCurrentMusic:Bool;
	private static var musicStopPosition:Float = 0;
	
	// Signals

//	public static var toggleAudioSignal(default, null) = new Signal<Bool>();
	public static var toggleSoundSignal(default, null) = new Signal<Bool>();
	public static var toggleMusicSignal(default, null) = new Signal<Bool>();

	// Methods

	public static function playSound(name:String):SoundChannel
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
		var soundChannel = sound.play(0);
		currentSounds.push(soundChannel);
		// Listeners
		soundChannel.addEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
		return soundChannel;
	}

	public static function stopAllSounds():Void
	{
		for (sc in currentSounds)
		{
			// Listeners
			sc.removeEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
			sc.stop();
		}
		currentSounds = [];
	}

	public static function playMusic(name:String, isLoop=true, startTime:Float=0):SoundChannel
	{
		if (name == null)
		{
			return null;
		}
		// Skip same
		if (currentMusic == name && isLoop == isLoopCurrentMusic)
		{
			return musicByName[name];
		}
		
		// Stop previous
		stopMusic(currentMusic);

		currentMusic = name;
		isLoopCurrentMusic = isLoop;
		if (!isMusicOn)
		{
			return null;
		}
		// Get sound from assets
		var assetName = getAssetName(name);
		var sound = ResourceManager.getMusic(assetName);
		if (sound == null)
		{
			return null;
		}
		
		// Play new
		var st = new SoundTransform(.2);
		var soundChannel = sound.play(startTime, isLoop ? musicLoopCount : 0, st);
		musicByName[name] = soundChannel;
		// Listeners
		soundChannel.addEventListener(Event.SOUND_COMPLETE, music_soundCompleteHandler);
		return soundChannel;
	}

	public static function stopMusic(name:String=null):Bool
	{
		if (name == null)
		{
			name = currentMusic;
		}
		var soundChannel = musicByName[name];
		if (soundChannel == null)
		{
			return false;
		}
		musicByName.remove(name);
		musicStopPosition = soundChannel.position;
		// Listeners
		soundChannel.removeEventListener(Event.SOUND_COMPLETE, music_soundCompleteHandler);
		soundChannel.stop();
		// (Should be after musicByName.remove() to prevent infinite recursion)
		if (name == currentMusic)
		{
			currentMusic = null;
		}
		return true;
	}

	private static function refreshSound():Void
	{
		if (!isSoundOn)
		{
			stopAllSounds();
		}
	}

	private static function refreshMusic():Void
	{
		if (isMusicOn)
		{
			playMusic(lastStoppedMusic, isLoopCurrentMusic, musicStopPosition);
		}
		else
		{
			// Save params to restore (on isMusicOn=true)
			lastStoppedMusic = currentMusic;
			stopMusic();
		}
	}

	private static function getAssetName(name:String):String
	{
		// Add dir path to all (namePrefix), and file extension if absent (nameExt).
		return namePrefix + name + (name.indexOf(".") == -1 ? nameExt : "");
	}
	
	// Handlers

	private static function sound_soundCompleteHandler(event:Event):Void
	{
		// (Always not null)
		var soundChannel = cast(event.currentTarget, SoundChannel);
		// Listeners
		soundChannel.removeEventListener(Event.SOUND_COMPLETE, sound_soundCompleteHandler);
		currentSounds.remove(soundChannel);
	}

	private static function music_soundCompleteHandler(event:Event):Void
	{
		stopMusic();
	}
}
