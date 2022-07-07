package v9.lib.net.parser;

import openfl.utils.ByteArray.ByteArrayData;
import openfl.utils.ByteArray;
import v7.lib.net.parser.IParser;
import v7.lib.util.BytesUtil;
import v7.lib.util.Log;

/**
 * MultiParser.
 * 
 * Changes:
 *  - fix bug, when parser version changed on client side and not yet changed 
 *  on server, so message in wrong (old) format might be received, so they 
 *  won't be parsed. Solution is to use separate parsers for income and outcome data.
 * 
 * Note: outputVersion changed only by serialize() or external code (e.g. Protocol), 
 * inputVersion -- only by parse(), i.e. by data from server.
 */
class MultiParser implements IMultiParser
{
	// Settings
	
	public var parserByVersion:Map<String, Dynamic>;

	// State

//	// If we change version from outside code, we change outputVersion
//	@:isVar
//	public var version(get, set):String;
//	public function get_version():String
//	{
//		return outputVersion;
//	}
//	public function set_version(value:String):String
//	{
//		return outputVersion = value;
//	}
	
	// For serialize() (sending)
	public var outputVersion(default, set):String;
	public function set_outputVersion(value:String):String
	{
		if (outputVersion != value && parserByVersion != null && parserByVersion.exists(value))
		{
			var prevVersion = outputVersion;
			// Set
			outputVersion = value;
			
			// Change parser
			outputParser = getParserByVersion(value);

			isOutputBinary = outputParser != null ? outputParser.isBinary : false;
			Log.debug('Output VERSION changed: $prevVersion -> $outputVersion current-outputParser: $outputParser');
		}
		return outputVersion;
	}

	// For parse() (receiving)
	public var inputVersion(default, set):String;
	public function set_inputVersion(value:String):String
	{
		if (inputVersion != value && parserByVersion != null && parserByVersion.exists(value))
		{
			var prevVersion = inputVersion;
			// Set
			inputVersion = value;

			// Change parser
			inputParser = getParserByVersion(value);

			isBinary = inputParser != null ? inputParser.isBinary : false;
			isInputBinary = inputParser != null ? inputParser.isBinary : false;
			Log.debug('Input VERSION changed: $prevVersion -> $inputVersion current-inputParser: $inputParser');
		}
		return inputVersion;
	}

	public var isBinary(default, null):Bool;
	public var isOutputBinary(default, null):Bool;
	public var isInputBinary(default, null):Bool;
	
	private var outputParser:IParser;
	private var inputParser:IParser;

	private var tempVersionBytes = new ByteArray();
	
	// Init

	public function new()
	{
	}

	// Methods

	public function serialize(object:Dynamic):Dynamic
	{
		var result:Dynamic;
		// Version data
		if (Std.isOfType(object, String) && parserByVersion.exists(object))
		{
			// Encode version data to change it also on server side
			if (isOutputBinary)
			{
				tempVersionBytes.clear();
				tempVersionBytes.writeUTFBytes(object);
				result = tempVersionBytes;
			}
			else
			{
				result = object;
			}
			// Change version (should be after encoding to do not change isBinary)
			outputVersion = object;
			return result;
		}
		
		// Not version data
		if (outputParser == null)
		{
			Log.error('Valid version is not chosen, parser not assigned, so object: $object can not be serialized!');
			return null;
		}

		result = outputParser.serialize(object);
		return result;
	}

	public function parse(plain:Dynamic):Array<Dynamic>
	{
		if (plain == null)
		{
			return plain;
		}
		
		// Change version by data
		var version = parseVersion(plain);
		if (version != null)
		{
			// Version parsed
			inputVersion = version;
			return [version];
		}
		
		if (inputParser == null)
		{
			if (Std.isOfType(plain, ByteArrayData))
			{
				// (For logs)
				plain = BytesUtil.toHex(plain);
			}
			Log.error('Valid version is not chosen, parser not assigned, so plain data: $plain can not be parsed!');
			return null;
		}

		// Normal parse
		return inputParser.parse(plain);
	}

	private function getParserByVersion(version:String):IParser
	{
		var parser:Dynamic = parserByVersion.get(version);
		var result;
		if (Std.isOfType(parser, IParser))
		{
			result = (parser:IParser);
		}
		else if (Reflect.isFunction(parser))
		{
			result = parser();
		}
		else if (Std.isOfType(parser, Class))
		{
			result = Type.createInstance(parser, []);
		}
		else
		{
			result = null;
		}
		return result;
	}

	private function parseVersion(plain:Dynamic):Dynamic
	{
		// Try parse version
		var version;
		var isBinary = Std.isOfType(plain, ByteArrayData);
		if (isBinary)
		{
			var ba:ByteArrayData = (plain:ByteArrayData);
			version = ba.readUTFBytes(ba.length);
		}
		else
		{
			version = plain;
		}
		// Set version
		if (parserByVersion != null && parserByVersion.exists(version))
		{
			return version;
		}
		// Not a version data
		// (Restore plain)
		if (isBinary)
		{
			// Restore position for ByteArray as current data is not a version data
			plain.position = 0;
		}
		return null;
	}
}
