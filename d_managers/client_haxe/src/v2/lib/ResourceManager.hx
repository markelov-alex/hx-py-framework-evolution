package v2.lib;

import yaml.Parser.ParserOptions;
import yaml.Yaml;
import v1.lib.Log;
import haxe.Exception;
import openfl.utils.Assets;
import haxe.Json;

/**
 * ResourceManager.
 * 
 * Get existing assets or load from Internet.
 */
class ResourceManager extends v1.lib.ResourceManager
{
	// Settings
	
	public static var assetNameByName = [
		"lang" => "assets/lang.json",
//		"" => "",
	];

	// State

	// Methods

	/**
	 * Get parsed JSON/YAML data object or just plain text string.
	 */
	public static function getData(assetName:String):Dynamic
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
