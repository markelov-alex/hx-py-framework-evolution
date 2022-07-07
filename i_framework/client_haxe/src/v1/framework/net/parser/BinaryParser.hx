package v1.framework.net.parser;

import openfl.utils.ByteArray;
import openfl.utils.Endian;
import v1.framework.util.BytesUtil;
import v1.framework.util.Log;

/**
 * BinaryParser.
 * 
 */
class BinaryParser implements IParser
{
	
	// Settings

	public var isBinary(default, null):Bool = true;
	public var defaultEndian:Endian = Endian.BIG_ENDIAN;
	// For isBinary=true
	public var useEndianInData = true;
	
	public var codeByString:Map<String, Int> = new Map();
	// Generated automatically using codeByString
	public var stringByCode:Map<Int, String>;
	public var codeByEndian:Map<Endian, Int> = [
		Endian.BIG_ENDIAN => 1,
		Endian.LITTLE_ENDIAN => 2,
	];
	public var endianByCode:Map<Int, Endian> = [
		1 => Endian.BIG_ENDIAN, 
		2 => Endian.LITTLE_ENDIAN,
	];
	
	// State
	
	// For using in serialize()
	private var tempSerializeResult = new ByteArray();
	// For using in serializeArray()
	private var tempSerializeCommandBytes = new ByteArray();
	private var tempSerializeItemBytes = new ByteArray();
	
	private var writeInt = BytesUtil.writeInt;
	private var readInt = BytesUtil.readInt;

	// Init

	public function new()
	{
		init();
		stringByCode = [for (k => v in codeByString) v => k];
		#if (debug && test)
		test();
		#end
	}

	private function init():Void
	{
	}

	private function test():Void
	{
		BytesUtil.test();
	}

	// Methods

	// Note: Returning ByteArray will be reused on next serialize() call
	public function serialize(commands:Dynamic):Dynamic
	{
		// (Note: commands == null processed in serializeArray())
		tempSerializeResult.clear();
		tempSerializeResult.endian = defaultEndian;
		var commandArray:Array<Dynamic> = Std.isOfType(commands, Array) ? commands : [commands];
		serializeArray(tempSerializeResult, commandArray, tempSerializeCommandBytes, 
			serializeCommand, useEndianInData, codeByEndian);
		return tempSerializeResult;
	}

	public function parse(plain:Dynamic):Array<Dynamic>
	{
		// (Note: plain == null processed in parseArray())
		if (!Std.isOfType(plain, ByteArrayData))
		{
			Log.error('For binary parser data also should be binary! ' +
				'ByteArray instance expected instead of $plain.');
			return [];
		}
		var dataBytes:ByteArray = plain;
		dataBytes.endian = defaultEndian;
		dataBytes.position = 0;
		Log.debug('Parse: ${BytesUtil.toHex(dataBytes)}');
		var result = parseArray(dataBytes, parseCommand, useEndianInData, endianByCode);
		Log.debug(' Parsed: $result');
		return result;
	}
	
	// Override
	private function serializeCommand(dataBytes:ByteArray, item:Dynamic):Void
	{
	}
	
	// Override
	private function parseCommand(dataBytes:ByteArray, length:Int):Dynamic
	{
		return null;
	}
	
	// Utility

	// Array with items of not fixed length in format: 
	//  endian + length + body + endian + length + body + ...
	// or
	//  length + body + length + body + ...
	// Endian added for commands. 
	// todo add protocol version in addition to endian (in v6)
	private function serializeArray(dataBytes:ByteArray, array:Array<Dynamic>,
									tempItemBytes:ByteArray, serializeItem:(ByteArray, Dynamic)->Void,
									isSerializeEndian = false, codeByEndian:Map<Endian, Int>=null):Void
	{
		if (array == null)
		{
			return;
		}

		tempItemBytes.endian = dataBytes.endian;
		var endianCode = codeByEndian != null ? codeByEndian.get(dataBytes.endian) : null;
		for (item in array)
		{
			// Get body data
			tempItemBytes.clear();
			serializeItem(tempItemBytes, item);
			
			// Write
			// Header
			if (isSerializeEndian)
			{
				dataBytes.writeByte(endianCode);
				//writeInt(dataBytes, endianCode, 1);
			}
			writeInt(dataBytes, tempItemBytes.length, 2);
			// Body
			dataBytes.writeBytes(tempItemBytes);
		}
	}

	private function parseArray(dataBytes:ByteArray, parseItem:(ByteArray, Int)->Dynamic,
								isParseEndian = false, endianByCode:Map<Int, Endian>=null):Array<Dynamic>
	{
		if (dataBytes == null || dataBytes.length == 0)
		{
			return null;
		}
		var result = [];
		var dataLength = (dataBytes.length:Int);
		var minLength = if (isParseEndian) 3 else 2;
		if (dataLength < minLength)
		{
			// Not enough bytes even for reading item length field (wait for more bytes)
			return null;
		}
		
		while ((dataBytes.position:Int) < dataLength)
		{
			var itemStart:Int = dataBytes.position;
			var itemLength = 0;
			if (isParseEndian)
			{
				// Read 1 byte
				var endianCode = dataBytes.readUnsignedByte();
				//var endianCode = readInt(dataBytes, 1);
				dataBytes.endian = endianByCode.get(endianCode);
				itemLength += 1;
			}
			// Read 2 bytes
			var length = readInt(dataBytes, 2);
			itemLength += 2;
			itemLength += length;
			var itemEnd = (dataBytes.position:Int) + length; // Use separate local var for debugging
			if (itemEnd > dataLength)
			{
				// Leave last bytes unparsed as they are not yet complete
				dataBytes.position = itemStart;
				break;
			}
			// Read length bytes
			result.push(parseItem(dataBytes, length));
			// Check all length bytes were read
			if ((dataBytes.position:Int) != itemStart + itemLength)
			{
				Log.error('${itemStart + itemLength - (dataBytes.position:Int)} bytes left unread and ' + 
					'unparsed! Your custom binary parser should be fixed!');
				dataBytes.position = itemStart + itemLength;
			}
		}
		return result;
	}
	
	private function serializeIntArray(dataBytes:ByteArray, array:Array<Int>, itemLength:Int,
									   isSigned=false):Void
	{
		if (array == null || array.length == 0)
		{
			return;
		}
		
		for (item in array)
		{
			writeInt(dataBytes, item, itemLength, isSigned);
		}
	}
	
	private function parseIntArray(dataBytes:ByteArray, length:Int, itemLength:Int,
								   isSigned=false):Array<Int>
	{
		if (length <= 0 || itemLength <=0)
		{
			return [];
		}
		
		var itemCount = Math.ceil(length / itemLength);
		if (itemCount * itemLength != length)
		{
			Log.info('DataBytes: ${BytesUtil.toHex(dataBytes)} position: ${dataBytes.position} length: {length}');
			Log.info('Selected dataBytes: ${BytesUtil.toHex(dataBytes, dataBytes.position, length)}');
			Log.error('Length: $length should be divideable by itemLength: $itemLength! itemCount: $itemCount');
		}
		var result = [for (i in 0...itemCount) readInt(dataBytes, itemLength, isSigned)];
		return result;
	}
}
