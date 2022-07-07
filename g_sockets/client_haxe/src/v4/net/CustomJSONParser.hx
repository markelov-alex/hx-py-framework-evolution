package v4.net;

import v3.lib.net.parser.JSONParser;
import v4.lib.net.parser.DataConverter;

/**
 * CustomJSONParser.
 * 
 */
class CustomJSONParser extends JSONParser
{
	// Settings

	// State
	
	private var converter = new DataConverter();

	// Init

	public function new()
	{
		super();

		converter.codeField = "code";
		converter.fieldsByCode["set"] = ["code", "name", "data"];
		converter.fieldsByCode["update"] = ["code", "name", "data"];
	}

	// Methods

	override public function serialize(commands:Dynamic):Dynamic
	{
		commands = converter.serialize(commands);
		return super.serialize(commands);
	}

	override public function parse(plain:Dynamic):Array<Dynamic>
	{
		var result = super.parse(plain);
		return converter.parse(result);
	}
}
