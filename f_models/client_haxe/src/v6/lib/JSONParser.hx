package v6.lib;

import haxe.Json;

/**
 * JSONParser.
 * 
 */
class JSONParser implements IParser
{
	// Settings

	// State

	// Init

	//public function new()
	//{
	//}

	// Methods

	public function serialize(commands:Dynamic):Dynamic
	{
		return Json.stringify(commands);
	}

	public function parse(plain:Dynamic):Array<Dynamic>
	{
		if (plain == null)
		{
			return null;
		}
		var data:Dynamic = Json.parse(plain);
		return Std.isOfType(data, Array) ? data : [data];
	}
}
