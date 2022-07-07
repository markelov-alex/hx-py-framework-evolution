package v7.lib.util;

import openfl.errors.ArgumentError;
import openfl.errors.EOFError;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import v7.lib.util.Assert;

/**
 * BytesUtil.
 * 
 */
class BytesUtil
{
	// Static

	public static function test():Void
	{
		Log.debug("(Start BytesUtil.test)");
		// Test write
		var bytes = new ByteArray();
		writeInt(bytes, 127, 1);
		writeInt(bytes, 127, 1, true);
		writeInt(bytes, -127, 1, true);
		writeInt(bytes, 127, 2);
		writeInt(bytes, 127, 2, true);
		writeInt(bytes, -127, 2, true);
//		writeInt(bytes, 127, 3);//error: Exceeds max value of Int in Haxe
		writeInt(bytes, 127, 3, true);
		writeInt(bytes, -127, 3, true);
//		writeInt(bytes, 127, 4);//error: Exceeds max value of Int in Haxe
		writeInt(bytes, 127, 4, true);
		writeInt(bytes, -127, 4, true);
		bytes.endian = Endian.LITTLE_ENDIAN;
		writeInt(bytes, 127, 2);
		writeInt(bytes, 127, 3, true);
		writeInt(bytes, -127, 4, true);
		bytes.endian = Endian.BIG_ENDIAN;
		var expectedHex = "0x 7f 7f 81 00 7f 00 7f ff 81 00 00 7f ff ff 81 00 00 00 7f ff ff ff 81 " + 
			// Little endian:
			"7f 00 7f 00 00 81 ff ff ff ";
		var currentHex = toHex(bytes);
		Assert.assertEqual(expectedHex, currentHex);
		// (Bytes constructor sets endian to little)
		bytes.endian = Endian.BIG_ENDIAN;

		// Test read
		bytes.position = 0;
		Assert.assertEqual(127, readInt(bytes, 1));
		Assert.assertEqual(127, readInt(bytes, 1, true));
		Assert.assertEqual(-127, readInt(bytes, 1, true));
		Assert.assertEqual(127, readInt(bytes, 2));
		Assert.assertEqual(127, readInt(bytes, 2, true));
		Assert.assertEqual(-127, readInt(bytes, 2, true));
//		Assert.assertEqual(127, readInt(bytes, 3));//error
		Assert.assertEqual(127, readInt(bytes, 3, true));
		Assert.assertEqual(-127, readInt(bytes, 3, true));
//		Assert.assertEqual(127, readInt(bytes, 4));//error
		Assert.assertEqual(127, readInt(bytes, 4, true));
		Assert.assertEqual(-127, readInt(bytes, 4, true));
		bytes.endian = Endian.LITTLE_ENDIAN;
		Assert.assertEqual(127, readInt(bytes, 2));
		Assert.assertEqual(127, readInt(bytes, 3, true));
		Assert.assertEqual(-127, readInt(bytes, 4, true));
		bytes.endian = Endian.BIG_ENDIAN;

		// Test max
		bytes.clear();
		writeInt(bytes, (1 << 8) - 1, 1);// max
		//writeInt(bytes, (1 << 8), 1);// error: max + 1
		writeInt(bytes, (1 << 16) - 1, 2);// max
		//writeInt(bytes, (1 << 16), 2);// error: max + 1
		writeInt(bytes, Std.int((1 << 24) / 2) - 1, 3, true);// max
		//writeInt(bytes, Std.int((1 << 24) / 2), 3, true);// error: max + 1
		bytes.position = 0;
		Assert.assertEqual((1 << 8) - 1, readInt(bytes, 1));
		Assert.assertEqual((1 << 16) - 1, readInt(bytes, 2));
		Assert.assertEqual(Std.int((1 << 24) / 2) - 1, readInt(bytes, 3, true));
		bytes.clear();
		
		// Test toUTF()
		var zero = "\\x00";
		bytes.writeByte(0);
		bytes.writeUTFBytes("abcdef");
		bytes.writeByte(0);
		bytes.writeUTFBytes("ghijkl");
		Assert.assertEqual('${zero}abcdef${zero}ghijkl', BytesUtil.toUTF(bytes));
		bytes.writeByte(0);
		Assert.assertEqual('${zero}abcdef${zero}ghijkl${zero}', BytesUtil.toUTF(bytes));
		bytes.clear();
		bytes.writeUTFBytes("abcdef");
		Assert.assertEqual("abcdef", BytesUtil.toUTF(bytes));
		bytes.clear();
		Log.debug("(End BytesUtil.test)");
	}

	public static function writeInt(bytes:ByteArray, value:Int, length:Int, signed:Bool=false):Void
	{
		// Haxe (at least for 32-bit Flash Player) has only 4-byte signed Int as maximum integer type
		if (length <= 0 || length > 4 || (!signed && length > 2))
		{
			throw new ArgumentError("Length should be > 0, <= 4 for signed, and > 2 for unsigned!");
		}
		var max = Math.pow(2, length * 8) - 1;
		if (signed)
		{
			max = Std.int(max / 2);
		}
		var min = signed ? -max - 1 : 0;
		Assert.assert(value >= min && value <= max,
		'To be written in $length bytes value: $value should be within an ' +
		'interval [$min, $max]!');

		var isLittleEndian = bytes.endian == Endian.LITTLE_ENDIAN;
		var shift = if (isLittleEndian) 0 else 8 * (length - 1);
		var dshift = if (isLittleEndian) 8 else -8;
		for (i in 0...length)
		{
			bytes.writeByte((value >> shift) & 0xFF);
			shift += dshift;
		}
	}

	public static function readInt(bytes:ByteArray, length:Int, signed:Bool=false):Int
	{
		// Haxe (at least for 32-bit Flash Player) has only 4-byte signed Int as maximum integer type
		if (length <= 0 || length > 4 || (!signed && length > 2))
		{
			throw new ArgumentError("Length should be > 0, <= 4 for signed, and > 2 for unsigned!");
		}
		if (bytes.position + length > bytes.length)
		{
			throw new EOFError();
			return 0;
		}
		var bytesArray:Array<Int> = [for (i in 0...length) bytes.readUnsignedByte()];
		var result = 0;
		var isLittleEndian = bytes.endian == Endian.LITTLE_ENDIAN;
		var shift = if (isLittleEndian) 0 else 8 * (length - 1);
		var dshift = if (isLittleEndian) 8 else -8;
		for (b in bytesArray)
		{
			result = result | (b << shift);
			shift += dshift;
		}
		if (signed)
		{
			// Now result is always positive
			// Check the most significant bit (MSB)
			var i = 0x80 << ((length - 1) * 8);
			if ((result & i) != 0)
			{
				// MSB is 1, so it is a negative number (with different modulo value)
				// Find out the real negative value = max + 1 - value
				// (Doesn't work for length=4 as 0x1 << 32 overflows max integer value)
				if (length == 4)
				{
					var a = 0x1 << (length * 8 - 1); // A half
					result -= a;
					result -= a;
				}
				else
				{
					result -= 0x1 << (length * 8);
				}
			}
		}
		return result;
	}

	// From haxe.io.Bytes.toHex() (to do not use Bytes.ofData(ba).toHex(), 
	// which creates new instance of Bytes, end changes endian in source ByteArray)
	// Changes with original: 
	//  - add space between bytes;
	// 	- offset, length parameters;
	//  - refactoring.
	private static final digits = "0123456789abcdef";
	private static final digitByValue = [for (i in 0...digits.length) digits.charCodeAt(i)];
	public static function toHex(byteArray:ByteArray, offset=0, ?length=-1):String
	{
		if (byteArray == null)
		{
			return null;
		}
		if (offset >= (byteArray.length:Int))
		{
			return "";
		}
		var start = if (offset < 0) offset = byteArray.length + offset else offset;
		var end = if (length == null || length < 0 || length > (byteArray.length:Int)) byteArray.length else start + length;

		var result = new StringBuf();
		for (i in start...end)
		{
			var c = byteArray[i];
			result.add(" ");
			result.addChar(digitByValue[c >> 4]);
			result.addChar(digitByValue[c & 15]);
		}
		return result.length > 0 ? "0x" + result.toString() : "";
	}

	public static function toUTF(byteArray:ByteArray, offset=0, ?length=-1):String
	{
		if (byteArray == null)
		{
			return null;
		}
		if (offset >= (byteArray.length:Int))
		{
			return "";
		}
//		// Read
//		byteArray.position = offset;
//		// Note, that readUTFBytes() doesn't read after a first zero-byte (0x00), 
//		// there could be not all data in readable form returned
//		var result = byteArray.readUTFBytes(length);

		var start = if (offset < 0) offset = byteArray.length + offset else offset;
		var end = if (length == null || length < 0 || length > (byteArray.length:Int)) byteArray.length else start + length;

		// Save position
		var pos = byteArray.position;

		// Find all zero-bytes
		var zeroByteIndexes = [];
		byteArray.position = start;
		for (i in start...end)
		{
			if (byteArray.readByte() == 0)
			{
				zeroByteIndexes.push(i);
			}
		}

		// Read (before, between, and after zero-bytes)
		byteArray.position = start;
		var zero = "\\x00";
		var result = "";
		for (index in zeroByteIndexes)
		{
			result += byteArray.readUTFBytes(index - byteArray.position);
			result += zero;
			byteArray.position = index + 1;
		}
		result += byteArray.readUTFBytes(end - byteArray.position);

		// Restore position
		byteArray.position = pos;
		return result;
	}
}
