package v1.framework;

import haxe.Exception;
import openfl.net.SharedObject;
import v1.framework.util.Log;
import v1.framework.util.Signal;
/**
 * LangManager.
 * 
 */
class LangManager extends Base
{
	// Settings

	public var defaultAssetName = "lang";

	// State

	private var shared:SharedObject = SharedObject.getLocal("managers");
	private var resource:ResourceManager;

	public var isEnabled = true;
	public var defaultLang:String = "en";
	public var langs = ["en", "ru", "de"];
	public var actualLangs(default, null):Array<String>;
	
	public var dictByLang(default, set):Map<String, Map<String, String>> = new Map();
	public function set_dictByLang(value:Map<String, Map<String, String>>):Map<String, Map<String, String>>
	{
		if (dictByLang != value)
		{
			dictByLang = value;
			// Refresh
			refreshData();
		}
		return value;
	}
	
	public var currentLang(default, set):String;
	public function set_currentLang(value:String):String
	{
		if (currentLang != value) // && (currentLang == null || dictByLang.exists(value)))
		{
			currentLang = value;
			shared.data.currentLang = value;
			refreshData();
			// LangManager should be enabled for all labels to update their texts
			if (isEnabled)
			{
				// Dispatch
				currentLangChangeSignal.dispatch(value);
			}
		}
		return value;
	}
	
	private var currentDict:Map<String, String> = new Map();
	
	// Signals

	public var currentLangChangeSignal(default, null) = new Signal<String>();

	// Init

	public function new()
	{
		super();

		if (shared.data.currentLang != null)
		{
			currentLang = shared.data.currentLang;
		}
		else
		{
			// Initialize shared.data
			shared.data.currentLang = currentLang;
		}
		
		// Default
		if (currentLang == null)
		{
			currentLang = defaultLang;
		}
		actualLangs = langs;
	}

	override private function init():Void
	{
		super.init();

		// Throws exception if more than 1 instance
		ioc.setSingleton(LangManager, this);
		resource = ioc.getSingleton(ResourceManager);
	}

	override public function dispose():Void
	{
		currentLangChangeSignal.dispose();
		
		resource = null;
		
		super.dispose();
	}

	// Methods

	public function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}

		// Get/load data
		Log.debug('Load: $assetName');
		var data = resource.getData(assetName);
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
						Log.error("Unexpected data while parsing in LangManager.load()! " + e.details());
						#if debug
						throw e;
						#end
						continue;
					}
				}
				dictByLang[lang] = dict;
			}

			refreshData();
		}
	}

	private function refreshData():Void
	{
		actualLangs = if (langs != null) [for (l in langs) if (dictByLang.exists(l)) l] else [];
		currentDict = dictByLang[currentLang];
	}

	public function get(key:String):String
	{
		if (currentDict == null || key == null)
		{
			return key;
		}
		var value = currentDict[key];
		return if (value != null) value else key;
	}
}
