package v4.lib.net.parser;

import v3.lib.net.parser.IParser;

/**
 * DataConverter.
 * 
 * Convert JSON objects to list to make messages transmitting via sockets shorter.
 */
class DataConverter implements IParser
{
	// Settings

	public var isBinary(default, null):Bool = false;

	public var codeIndex:Int = 0;
	public var codeField:String = "code";
	
	public var fieldsByCode:Map<String, Array<String>> = new Map();

	// State

	// Init

	public function new(?codeIndex:Int, ?codeField:String, 
						?fieldsByCode:Map<String, Array<String>>)
	{
		if (codeIndex != 0)
		{
			this.codeIndex = codeIndex;
		}
		if (codeField != null)
		{
			this.codeField = codeField;
		}
		if (fieldsByCode != null)
		{
			this.fieldsByCode = fieldsByCode;
		}
	}

	// Objects to Arrays
	public function serialize(object:Dynamic):Dynamic
	{
		if (object == null)
		{
			return [];
		}
		// Command -> list of commands
		var objects = if (Std.isOfType(object, Array)) object else [object];
		
		// Convert each or leave same
		var result = [];
		for (obj in objects)
		{
			var code = Std.string(Reflect.field(obj, codeField));
			var fields = fieldsByCode[code];
			if (fields != null)
			{
				var arr = [for (field in fields) Reflect.field(obj, field)];
				result.push(arr);
			}
			else
			{
				result.push(obj);
			}
		}
		return result;
	}

	// Arrays to Objects
	public function parse(plain:Dynamic):Array<Dynamic>
	{
		if (plain == null)
		{
			return plain;
		}
		// Command -> list of commands
		// "string" -> ["string"]
		var arrays = if (!Std.isOfType(plain, Array)) [plain] else plain;
		// ["a", "b"] -> [["a", "b"]] 
		arrays = if (plain.length > 0 && !Std.isOfType(plain[0], Array)) [arrays] else arrays;
		
		// Convert each or leave same
		var result = [];
		for (arr in arrays)
		{
			var code = Std.string(arr[codeIndex]);
			var fields = fieldsByCode[code];
			if (fields != null)
			{
				var obj = {};
				for (i => field in fields)
				{
					var value = arr[i];
					Reflect.setField(obj, field, value);
				}
				result.push(obj);
			}
			else
			{
				result.push(arr);
			}
		}
		return result;
	}

	// Methods

}
