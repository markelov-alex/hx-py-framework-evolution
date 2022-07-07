package v3.lib;

import haxe.Exception;
import haxe.Json;
import openfl.display.MovieClip;
import openfl.media.Sound;
import openfl.utils.AssetLibrary;
import openfl.utils.Assets;
import v1.lib.Log;
import yaml.Parser.ParserOptions;
import yaml.Yaml;

/**
 * ResourceManager.
 * 
 * If you need an asset use ResourceManager, not Assets.
 * 
 * As Assets.exists() doesn't work and Assets.getMovieClip() throws exception 
 * if library is not loaded, we have to replace standard Assets class with our 
 * ResourceManager, where we'll mark which libraries are loaded and which are not.
 * 
 * Besides, it's more convenient to use:
 *  	ResourceManager.getInstance().createMovieClip(assetName, function(mc:MovieClip)
 *  	{
 *  		skin = mc;
 *  	});
 * instead of:
 * 		var libraryName = assetName.split(":")[0];
 * 		Assets.loadLibrary(libraryName).onComplete(function(library)
 * 		{
 * 			skin = Assets.getMovieClip(assetName);
 * 		});
 * 
 * TODO maybe create incremental load/unload: unload call count should be same as 
 *  for load to really unload the library.
 */
class ResourceManager
{
	// Settings

	public var assetNameByName = [
		"lang" => "assets/lang.json",
		"lang.json" => "assets/lang.json",
		"lang.yaml" => "assets/lang.yaml",
		"lang.yml" => "assets/lang.yml",
	];

	// State

	private static var instance:ResourceManager;
	public static function getInstance():ResourceManager
	{
		if (instance == null)
		{
			// Previous way
			//instance = new ResourceManager();
			// With IoC
			instance = IoC.getInstance().getSingleton(ResourceManager);
			// Or same (as singleton set to IoC from manager's constructor):
			//instance = IoC.getInstance().create(ResourceManager);
		}
		return instance;
		// Or even simplier
		//return IoC.getInstance().getSingleton(ResourceManager);
	}
	
	private var loadingLibraries:Array<String> = [];
	private var loadedLibraries:Array<String> = [];
	private var callbacksByLibraryName:Map<String, Array<(String)->Void>> = new Map();
	
	// Init

	public function new()
	{
		// Throws exception if more than 1 instance
		IoC.getInstance().setSingleton(ResourceManager, this);
	}

	// Methods

	// Load
	
	/**
	 * Preload libraries for assets which will be needed soon.
	 * For example, when we reached lobby, we can immediately 
	 * start loading assets for game to wait less time when we 
	 * will open game screen.
	 * 
	 * @param assetNameOrList "game", "game:AssetGameScreen", 
	 * 	"game1:AssetGameScreen,game2:AssetGameScreen,game3"
	 */
	public function loadLibrariesFor(assetNameOrList:String):Void
	{
		if (assetNameOrList == null)
		{
			return;
		}
		var assetNames:Array<String> = assetNameOrList.split(",");
		var libraryNames = [for (assetName in assetNames) getLibraryName(assetName)];
		for (libraryName in libraryNames)
		{
			loadLibrary(libraryName);
		}
	}

	public function loadLibrary(libraryName:String, ?callback:(String)->Void):Void
	{
		// Already loaded
		if (loadedLibraries.contains(libraryName))
		{
			if (callback != null)
			{
				callback(libraryName);
			}
			return;
		}

		// Currently loading or will be loading soon (if exists)
		if (callback != null)
		{
			if (callbacksByLibraryName[libraryName] == null)
			{
				callbacksByLibraryName[libraryName] = [];
			}
			callbacksByLibraryName[libraryName].push(callback);
		}

		// Load if not loading yet
		if (onLibraryStartLoading(libraryName))
		{
			// Check libraryName
			var library = Assets.getLibrary(libraryName);
			if (library == null)
			{
				// Does not exist
				Log.error('There is no library with id: $libraryName! Please, check project.xml.');
				callbacksByLibraryName.remove(libraryName);
				return;
			}

			// Load
			var startTime = haxe.Timer.stamp();
			Assets.loadLibrary(libraryName).onComplete(function(assetLibrary:AssetLibrary):Void
			{
				// On loaded
				var callbacks = onLibraryLoaded(libraryName);
				Log.debug('Load library: $libraryName in ${haxe.Timer.stamp() - startTime} sec');
				if (callbacks != null)
				{
					for (callback in callbacks)
					{
						callback(libraryName);
					}
				}
			});
		}
	}

	/** 
	 * @param assetNameOrList "game", "game:AssetGameScreen", 
	 * 	"game1:AssetGameScreen,game2:AssetGameScreen,game3"
	 */
	public function unloadLibrariesFor(assetNameOrList:String):Void
	{
		if (assetNameOrList == null)
		{
			return;
		}
		var assetNames:Array<String> = assetNameOrList.split(",");
		var libraryNames = [for (assetName in assetNames) getLibraryName(assetName)];
		for (libraryName in libraryNames)
		{
			unloadLibrary(libraryName);
		}
	}

	public function unloadLibrary(libraryName:String):Void
	{
		if (!loadedLibraries.contains(libraryName))
		{
			return;
		}

		loadedLibraries.remove(libraryName);
		Assets.unloadLibrary(libraryName);
	}

	private function onLibraryStartLoading(libraryName:String):Bool
	{
		if (libraryName == null || libraryName == "" ||
			loadingLibraries.contains(libraryName) || loadedLibraries.contains(libraryName))
		{
			return false;
		}
		loadingLibraries.push(libraryName);
		return true;
	}

	private function onLibraryLoaded(libraryName:String):Array<(String)->Void>
	{
		if (!loadedLibraries.contains(libraryName))
		{
			loadedLibraries.push(libraryName);
		}
		if (loadingLibraries.contains(libraryName))
		{
			loadingLibraries.remove(libraryName);
		}

		var callbacks = callbacksByLibraryName[libraryName];
		callbacksByLibraryName.remove(libraryName);
		return callbacks;
	}
	
	// Create

	/**
	 * Load, create and return MovieClip into callback.
	 */
	public function createMovieClip(assetName:String, callback:(MovieClip) -> Void):Void
	{
		if (assetName == null || assetName == "")
		{
			callback(null);
			return;
		}

		var movieClip = getMovieClip(assetName);
		if (movieClip != null)
		{
			callback(movieClip);
			return;
		}

		// Load
		var libraryName = getLibraryName(assetName);
		loadLibrary(libraryName, function(libraryName:String):Void
		{
			var movieClip = Assets.getMovieClip(assetName);
			callback(movieClip);
		});
	}

	/**
	 * (For API completeness. Not practically used.)
	 */
	public function getMovieClip(assetName:String):MovieClip
	{
		if (assetName == null || assetName == "")
		{
			return null;
		}

		var libraryName = getLibraryName(assetName);
		if (!loadedLibraries.contains(libraryName))
		{
			// Not loaded yet
			return null;
		}

		return Assets.getMovieClip(assetName);
	}

	private function getLibraryName(assetName:String):String
	{
//		return if (assetName != null) assetName.split(":")[0] else null;
		var libraryName = if (assetName.indexOf(":") != -1)
			assetName.split(":")[0] else "default";
		return libraryName;
	}
	
	//public function getSound(assetName:String, callback:Sound->Void):Sound
	public function getSound(assetName:String):Sound
	{
		// TODO loading (maybe like createMovieClip())
//		Assets.loadSound(name).onComplete(function (sound:Sound) {
//			callback(sound);
//		});
		// As sounds and music are not necessary part of game, 
		// ignore if they absent (use try-catch)
		try
		{
			return Assets.getSound(assetName);
		}
		catch (e:Exception)
		{
			return null;
		}
	}
	
	// Now it is same as getSound(), but maybe sometimes it'll change
	//public function getMusic(assetName:String, callback:Sound->Void):Sound
	public function getMusic(assetName:String):Sound
	{
//		Assets.loadMusic(name).onComplete(function (sound:Sound) {
//			callback(sound);
//		});
		// As sounds and music are not necessary part of game, 
		// ignore if they absent (use try-catch)
		try
		{
			return Assets.getMusic(assetName);
		}
		catch (e:Exception)
		{
			return null;
		}
	}

	/**
	 * Get parsed JSON/YAML data object or just plain text string.
	 */
	//public function getData(assetName:String, callback:Dynamic->Void):Dynamic
	public function getData(assetName:String):Dynamic
	{
		var realAssetName = assetNameByName[assetName];
		if (realAssetName != null)
		{
			assetName = realAssetName;
		}
		var text = Assets.getText(assetName);
		var nameParts = assetName.split(".");
		var ext = nameParts.length > 1 ? nameParts[nameParts.length - 1] : "";
		try
		{
			switch (ext)
			{
				case "json":
					return Json.parse(text);
				case "yml" | "yaml":
					return Yaml.parse(text, new ParserOptions().useObjects());
			}
		}
		catch (e:Exception)
		{
			Log.error(e);
			return null;
		}
		return text;
	}
}
