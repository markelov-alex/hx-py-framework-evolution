package v4.lib;

import openfl.media.SoundChannel;
import openfl.net.SharedObject;
import v3.lib.AudioManager.Track;
/**
 * AudioManager.
 * 
 * As we have not special classes for sounds and music, we can not 
 * preconfig them in subclasess and substitute with IoC. 
 * So, external audio config file is created (JSON or YAML).
 */
class AudioManager extends v3.lib.AudioManager
{
	// Settings
	
	public var defaultAssetName = "audio.yml";
	private var defaultConfig:Track = {
		name: null, isLoop: false, startTime: 0, volume: 1, pan: 0,
	};

	// State

	private var shared:SharedObject = SharedObject.getLocal("managers");
	private var soundConfigByName = new Map<String, Track>();
	private var musicConfigByName = new Map<String, Track>();
	// (To do not apply again the track's config on current music on music turned on or looping)
	private var isRestoringMusic = false;

	override public function set_soundVolume(value:Float):Float
	{
		shared.data.soundVolume = value;
		return super.set_soundVolume(value);
	}

	override public function set_musicVolume(value:Float):Float
	{
		shared.data.musicVolume = value;
		return super.set_musicVolume(value);
	}

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

	public function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}

		// Get/load data
		var data = resourceManager.getData(assetName);
		if (data == null)
		{
			return;
		}
		
		// Set up manager
		for (key in Reflect.fields(data))
		{
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

	override public function playSound(name:String, volume:Float=1, pan:Float=0):SoundChannel
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
		return super.playSound(name, volume, pan);
	}

	override public function playMusic(name:Dynamic, isLoop=false, startTime:Float=0, volume:Float=1, pan:Float=0):SoundChannel
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
		
		return super.playMusic(name, isLoop, startTime, volume, pan);
	}

	override public function _playMusic(name:Dynamic, isLoop=false, startTime:Float=0, volume:Float=1, pan:Float=0):SoundChannel
	{
		// Apply config for track
		var config:Track = musicConfigByName[name];
		if (!isRestoringMusic && config != null)
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

		return super._playMusic(name, isLoop, startTime, volume, pan);
	}

	override public function stopMusic(name:Dynamic=null):SoundChannel
	{
		// Stop playlist by its real name - as list of tracks
		var config:Track = musicConfigByName[name];
		if (config != null && Std.isOfType(config.name, Array))
		{
			name = config.name;
		}
		
		return super.stopMusic(name);
	}

	override private function getAssetName(name:String, isMusic=false):String
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

	override private function refreshSoundOn():Void
	{
		super.refreshSoundOn();

		shared.data.isSoundOn = isSoundOn;
	}

	override private function refreshMusicOn():Void
	{
		isRestoringMusic = true;
		super.refreshMusicOn();
		isRestoringMusic = false;

		shared.data.isMusicOn = isMusicOn;
	}

	override private function checkCurrentMusicLoop():Bool
	{
		isRestoringMusic = true;
		var result = super.checkCurrentMusicLoop();
		isRestoringMusic = false;
		return result;
	}
}
