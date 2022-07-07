package v4.lib;

import openfl.net.SharedObject;
import haxe.Exception;
import v1.lib.Log;
/**
 * LangManager.
 * 
 * Changes:
 *  - loaded dictionaries not overwrite previous ones, but update them, 
 *  - so now multiple files can be loaded,
 *  - manager can also be set up by loaded data.
 */
class LangManager extends v3.lib.LangManager
{
	// Settings

	// State

	private var shared:SharedObject = SharedObject.getLocal("managers");

	private var isCurrentLangInitialized = false;
	override public function set_currentLang(value:String):String
	{
		// (Only update, not initialize shared.data)
		if (!isCurrentLangInitialized)
		{
			return currentLang;
		}
		shared.data.currentLang = value;
		return super.set_currentLang(value);
	}

	// Init

	public function new()
	{
		super();

		// isCurrentLangInitialized needed to skip currentLang=defaultLang in super()
		isCurrentLangInitialized = true;
		if (shared.data.currentLang != null)
		{
			currentLang = shared.data.currentLang;
		}
		else
		{
			// Initialize shared.data
			shared.data.currentLang = currentLang;
		}
	}

	override public function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}

		// Get/load data
		var data = resourceManager.getData(assetName);
		if (data != null)
		{
			// Set up manager and convert dict Objects -> lookup Maps
			var dictByLang = this.dictByLang;
			for (key in Reflect.fields(data))
			{
				var value:Dynamic = Reflect.getProperty(data, key);
				
				// Set up manager
				if (Reflect.hasField(this, key))
				{
					Reflect.setProperty(this, key, value);
					continue;
				}

				// Update lang lookup
				var lang = key;
				var dict = dictByLang[lang];
				if (dict == null)
				{
					dict = dictByLang[lang] = new Map();
				}
				for (key2 in Reflect.fields(value))
				{
					try
					{
						dict[key2] = Reflect.getProperty(value, key2);
					}
					catch (e:Exception)
					{
						Log.error("Unexpected data while parsing in LangManager.load()! " + e);
						continue;
					}
				}
				dictByLang[lang] = dict;
			}

			refreshData();
		}
	}

	// Methods

}
