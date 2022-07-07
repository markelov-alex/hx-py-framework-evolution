package v0.net.parser;

#if debug
import haxe.Json;
#end
import openfl.utils.ByteArray;
import v0.lib.net.parser.BinaryParser;
import v0.lib.util.Assert;
import v0.lib.util.Log;

/**
 * CustomBinaryParser.
 * 
 * For both dresser and coloring games.
 */
class CustomBinaryParser extends BinaryParser
{
	// Settings

	// State
	
	// Init

//	public function new()
//	{
//		super();
//	}

	override private function init():Void
	{
		// Note: Use big numbers (> 128) to test unsigned bytes encoded properly
		codeByString = [
			// Commands
			"get" => 3,
			"set" => 4,
			"update" => 250,
			// Names
			"dresserState" => -10,
			"pictureStates" => 120,
		];
		super.init();
	}

	override private function test():Void
	{
		super.test();

		trace('');
		Log.debug("(Start CustomBinaryParser.test)");
		// objectToIntArray()/intArrayToObject()
		var object1 = {"0": 2, "1": 3};
		var object2 = {"2": {"1": 3, "5": 6}};
		Assert.assertEqual(Std.string(object1), 
			Std.string(intArrayToObject(objectToIntArray(object1))));
		Assert.assertEqual(Std.string(object2), 
			Std.string(intArrayToObject(objectToIntArray(object2, 2), 2)));
		Assert.assertEqual(Std.string([2, 5, 6, 2, 1, 3, ]), 
			Std.string(objectToIntArray(object2, 2)));

		// serialize()/parse()
		var commands = [
			// Comment other commands when debugging
			{"code": "get", "name": "dresserState",
				"data": [2, 0, 1]},
			{"code": "update", "name": "dresserState",
				"data": {"0": 1, "2": 0}},
			{"code": "set", "name": "pictureStates",
				"data": [[1234567, 234567, -1, 34567], [0, 1234567]]},
			{"code": "update", "name": "pictureStates",
				"data": {"0": {"1": 5, "2": 6}, "3": {"5": 1234567}}},
		];
		Assert.assertEqual(Std.string(commands), Std.string(parse(serialize(commands))));
		
		// Compare result length with JSON
		compareWithJSONFormat(commands);
		Log.debug("(End CustomBinaryParser.test)");
		trace('');
	}
	
	private function compareWithJSONFormat(commands:Dynamic, ?commandsBytes:ByteArray):Void
	{
		#if debug
		var lengthJSON:Int = Json.stringify(commands).length;
		if (commandsBytes == null)
		{
			commandsBytes = serialize(commands);
		}
		var lengthBinary:Int = commandsBytes.length;
		Log.debug('(Length in JSON format: $lengthJSON in binary: $lengthBinary. ' + 
			'Ratio: ${lengthJSON / lengthBinary})');
		#end
	}

	// Methods

	override public function serialize(commands:Dynamic):Dynamic
	{
		var result = super.serialize(commands);
		compareWithJSONFormat(commands, result);
		return result;
	}

	override public function parse(plain:Dynamic):Array<Dynamic>
	{
		var result = super.parse(plain);
		compareWithJSONFormat(result, plain);
		return result;
	}

	override private function serializeCommand(dataBytes:ByteArray, item:Dynamic):Void
	{
		var command = item.command;
		var commandCode = codeByString.get(command);
		dataBytes.writeByte(commandCode);
		var name = item.name;
		var nameCode = codeByString.get(name);
		writeInt(dataBytes, nameCode, 1, true);
		var data = item.data;
		serializeDataField(dataBytes, command, name, data);
	}

	override private function parseCommand(dataBytes:ByteArray, length:Int):Dynamic
	{
		// 1 byte
		var commandCode = dataBytes.readUnsignedByte();
		var command = stringByCode.get(commandCode);
		// 1 byte
		var nameCode = readInt(dataBytes, 1, true);
		var name = stringByCode.get(nameCode);
		// The rest length - 2 bytes
		var data = parseDataField(dataBytes, length - 2, command, name);
		return {command: command, name: name, data: data};
	}

	private function serializeDataField(dataBytes:ByteArray, command:String, name:String, data:Dynamic):Void
	{
		if (name == "dresserState")
		{
			// For update
			if (data != null && !Std.isOfType(data, Array))
			{
				// {"0": 2, "1": 3} -> [0, 2, 1, 3]
				data = objectToIntArray(data, 1);
			}
			// [0, 2, 1, 3] -> bytes
			serializeIntArray(dataBytes, data, 1, false);
		}
		else if (name == "pictureStates")
		{
			if (command == "update")
			{
				// {"2": {"1": 3345234}} -> [2, 1, 3345234]
				data = objectToIntArray(data, 2);
				// [2, 1, 3345234] -> bytes
				serializeIntArray(dataBytes, data, 4, true);
			}
			else
			{
				var serializeItem = serializeIntArray.bind(_, _, 4, true);
				serializeArray(dataBytes, data, tempSerializeItemBytes, serializeItem);
			}
		}
	}
	
	private function parseDataField(dataBytes:ByteArray, length:Int, command:String, name:String):Dynamic
	{
		if (name == "dresserState")
		{
			var array = parseIntArray(dataBytes, length, 1, false);
			var data:Dynamic = command == "update" ? intArrayToObject(array, 1) : array;
			return data;
		}
		else if (name == "pictureStates")
		{
			if (command == "update")
			{
				var array = parseIntArray(dataBytes, length, 4, true);
				var data = intArrayToObject(array, 2);
				return data;
			}
			else
			{
				var parseItem = parseIntArray.bind(_, _, 4, true);
				var data = parseArray(dataBytes, parseItem);
				return data;
			}
		}
		return null;
	}
	
	// Utility

	// Our data structures in game are not very good for binary protocol, 
	// so it would be a good lesson for the future.
	// {"0": 2, "1": 3} -> [0, 2, 1, 3]
	// {"2": {"1": 3, "5": 6}} -> [2, 1, 3, 2, 5, 6]
	private function objectToIntArray(data:Dynamic, nesting=1):Array<Int>
	{
		var result = [];
		for (key in Reflect.fields(data))
		{
			var value = Reflect.field(data, key);
			// Works only for nesting == 1 or 2
			if (nesting > 1)
			{
				for (k in Reflect.fields(value))
				{
					result.push(Std.parseInt(key));
					result.push(Std.parseInt(k));
					result.push(Reflect.field(value, k));
				}
			}
			else
			{
				result.push(Std.parseInt(key));
				result.push(value);
			}
		}
		return result;
	}

	// [0, 2, 1, 3] -> {"0": 2, "1": 3} nesting=1
	// [2, 1, 3, 2, 5, 6] -> {"2": {"1": 3, "5": 6}} nesting=2
	// Works for any nesting > 0
	private function intArrayToObject(data:Dynamic, nesting=1):Dynamic
	{
		var result = {};
		var i = 0;
		var dataLength = data.length;
		while (i < dataLength)
		{
			if (i + nesting >= dataLength)
			{
				Log.error('Wrong item count in array: $data for parsing it ' +
				'to object with nesting: $nesting.');
				break;
			}
			var res = result;
			for (n in 0...nesting)
			{
				var key = Std.string(data[i]);
				i += 1;
				if (n < nesting - 1)
				{
					if (!Reflect.hasField(res, key))
					{
						Reflect.setField(res, key, {});
					}
					res = Reflect.field(res, key);
				}
				else
				{
					Reflect.setField(res, key, data[i]);
					i += 1;
				}
			}
		}
		return result;
	}
}
