package v6.lib.net.parser;

import openfl.utils.ByteArray.ByteArrayData;
import openfl.utils.ByteArray;

/**
 * AutoMultiParser.
 * 
 */
class AutoMultiParser extends MultiParser
{
	// Settings

	// State

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	// Already in MultiParser
//	override public function serialize(object:Dynamic):Dynamic
//	{
//		var result = super.serialize(object);
//		
//		// Change version by data (after version serialized)
//		if (Std.isOfType(object, String) && parserByVersion.exists(object))
//		{
//			version = object;
//		}
//		
//		return result;
//	}

	override public function parse(plain:Dynamic):Array<Dynamic>
	{
		// Change version by data (returns plain without version)
		plain = parseVersion(plain);
		// Parser data without version
		return super.parse(plain);
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
			// Plain is a version data
			this.version = version;
			return null;
		}
		// Not a version data
		// (Restore plain)
		if (isBinary)
		{
			// Restore position for ByteArray as current data is not a version data
			plain.position = 0;
		}
		return plain;
	}
}
