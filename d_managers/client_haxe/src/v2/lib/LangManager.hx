package v2.lib;

import v1.lib.LangManager in LangManager1;

/**
 * LangManager.
 * 
 */
class LangManager extends LangManager1
{
	// Settings
	
	public static var defaultAssetName = "lang";

	// State

	public static function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}

		// Get/load data
		// Note: To load other types of assets we would be forced to use 
		// v1.lib.ResourceManager, that is 2 different classes though with same name. 
		// That showes us, how static classes are not designated for inheritance.
		var data = ResourceManager.getData(assetName);
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
			LangManager1.dictByLang = dictByLang;
		}
	}

	// Methods
	
}
