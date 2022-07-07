package v3.lib;

import openfl.display.MovieClip;
import openfl.utils.AssetLibrary;
import openfl.utils.Assets;

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
 *  	ResourceManager.createMovieClip(assetName, function(mc:MovieClip)
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

	// State
	
	private static var loadingLibraries:Array<String> = [];
	private static var loadedLibraries:Array<String> = [];
	private static var callbacksByLibraryName:Map<String, Array<(String)->Void>> = new Map();
	
//	// Init
//
//	public function new()
//	{
//		super();
//	}

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
	public static function loadLibrariesFor(assetNameOrList:String):Void
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

	public static function loadLibrary(libraryName:String, ?callback:(String)->Void):Void
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
	public static function unloadLibrariesFor(assetNameOrList:String):Void
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

	public static function unloadLibrary(libraryName:String):Void
	{
		if (!loadedLibraries.contains(libraryName))
		{
			return;
		}

		loadedLibraries.remove(libraryName);
		Assets.unloadLibrary(libraryName);
	}

	private static function onLibraryStartLoading(libraryName:String):Bool
	{
		if (libraryName == null || libraryName == "" ||
			loadingLibraries.contains(libraryName) || loadedLibraries.contains(libraryName))
		{
			return false;
		}
		loadingLibraries.push(libraryName);
		return true;
	}

	private static function onLibraryLoaded(libraryName:String):Array<(String)->Void>
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
	public static function createMovieClip(assetName:String, callback:(MovieClip) -> Void):Void
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
	public static function getMovieClip(assetName:String):MovieClip
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

	private static function getLibraryName(assetName:String):String
	{
//		return if (assetName != null) assetName.split(":")[0] else null;
		var libraryName = if (assetName.indexOf(":") != -1)
			assetName.split(":")[0] else "default";
		return libraryName;
	}

}
