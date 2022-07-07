package v3.lib;

import v1.lib.Signal;

/**
 * LangManager.
 * 
 */
class LangManager
{
	// Settings

	public var defaultAssetName = "lang";

	// State

	private static var instance:LangManager;
	public static function getInstance():LangManager
	{
		if (instance == null)
		{
			// Previous way
			//instance = new LangManager();
			// With IoC
			instance = IoC.getInstance().getSingleton(LangManager);
			// Or same (as singleton set to IoC from manager's constructor):
			//instance = IoC.getInstance().create(LangManager);
		}
		return instance;
		// Or even simplier
		//return IoC.getInstance().getSingleton(LangManager);
	}
	
	private var resourceManager = ResourceManager.getInstance();

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
		// Throws exception if more than 1 instance
		IoC.getInstance().setSingleton(LangManager, this);
		
		// Default
		currentLang = defaultLang;
		actualLangs = langs;
	}

	public function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}

		// Get/load data
		var data = resourceManager.getData(assetName);
		if (data != null)
		{
			// Convert data Object -> lookup Map
			var dictByLang = new Map();
			for (l in Reflect.fields(data))
			{
				var dictData = Reflect.getProperty(data, l);
				var dict = new Map();
				for (key in Reflect.fields(dictData))
				{
					dict[key] = Reflect.getProperty(dictData, key);
				}
				dictByLang[l] = dict;
			}

			// Set lookup
			this.dictByLang = dictByLang;
		}
	}

	// Methods

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
