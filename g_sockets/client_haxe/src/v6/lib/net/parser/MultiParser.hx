package v6.lib.net.parser;

import openfl.utils.ByteArray.ByteArrayData;
import openfl.utils.ByteArray;
import v0.lib.Log;
import v3.lib.net.parser.IParser;
import v5.lib.net.parser.BytesUtil;

/**
 * MultiParser.
 * 
 */
class MultiParser implements IParser
{
	// Settings
	
	public var defaultVersion:String;
	public var parserByVersion:Map<String, Dynamic>;

	// State
	
	public var isBinary(default, null):Bool;
	
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
//			isBinary = current != null ? current.isBinary : false;
			// temp (as not all parsers have isBinary)
			isBinary = Type.getClassName(Type.getClass(current)).indexOf("Binary") != -1;
			Log.debug('MultiParser changed version: $prevVersion->$version current-parser: $current');
			
//			// Dispatch
//			currentVersionSignal.dispatch(value);
		}
		return version;
	}

	private var current:IParser;

	private var tempVersionBytes = new ByteArray();
	
	// Init

	public function new()
	{
		init();
	}

	// Override to change defaultVersion and parserByVersion
	private function init():Void
	{
		version = defaultVersion;
	}

	// Methods

	public function serialize(object:Dynamic):Dynamic
	{
		if (current == null)
		{
			Log.error('Valid version is not chosen, parser not assigned, so object: $object can not be serialized!');
			return null;
		}
		
		var result:Dynamic;
		// Version
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
			// Change version
			version = object;
		}
		// Not version
		else
		{
			result = current.serialize(object);
		}
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
