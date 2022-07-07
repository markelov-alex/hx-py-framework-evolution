package v7.lib.net.parser;

import openfl.utils.ByteArray.ByteArrayData;
import openfl.utils.ByteArray;
import v7.lib.net.parser.IParser;
import v7.lib.util.BytesUtil;
import v7.lib.util.Log;

/**
 * MultiParser.
 * 
 */
class MultiParser implements IMultiParser
{
	// Settings
	
	public var parserByVersion:Map<String, Dynamic>;

	// State
	
	public var versions(get, null):Array<String>;
	public function get_versions():Array<String>
	{
		var versions = [for (v in parserByVersion.keys()) v];
		versions.sort(function (a, b) { return a < b ? -1 : (a > b ? 1 : 0); });
		return versions;
	}
	
	public var version(default, set):String;
	public function set_version(value:String):String
	{
		if (version != value && parserByVersion != null && parserByVersion.exists(value))
		{
			var prevVersion = version;
			// Set
			version = value;
			
			// Change parser
			var parser:Dynamic = parserByVersion.get(value);
			if (Std.isOfType(parser, IParser))
			{
				current = (parser:IParser);
			}
			else if (Reflect.isFunction(parser))
			{
				current = parser();
			}
			else if (Std.isOfType(parser, Class))
			{
				current = Type.createInstance(parser, []);
			}
			else
			{
				current = null;
			}
			isBinary = current != null ? current.isBinary : false;
			Log.debug('MultiParser changed version: $prevVersion->$version current-parser: $current');
		}
		return version;
	}

	public var isBinary(default, null):Bool;

	private var current:IParser;

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
			if (isBinary)
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
			version = object;
			return result;
		}
		
		// Not version data
		if (current == null)
		{
			Log.error('Valid version is not chosen, parser not assigned, so object: $object can not be serialized!');
			return null;
		}

		result = current.serialize(object);
		return result;
	}

	public function parse(plain:Dynamic):Array<Dynamic>
	{
		if (plain == null)
		{
			return plain;
		}
		if (current == null)
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
		return current.parse(plain);
	}
}
