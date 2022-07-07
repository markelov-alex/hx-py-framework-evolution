package v1.net.parser;

import v0.net.parser.CustomMultiParser as CustomMultiParser0;
import v1.net.parser.CustomBinaryParser;
import v1.net.parser.CustomJSONParser;

/**
 * CustomMultiParser.
 * 
 */
class CustomMultiParser extends CustomMultiParser0
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();
		
//		// Add one that doesn't exist on server for testing how server would handle that
//		// Note: System can revert wrong parser only the previous one was of same type 
//		// (binary or string). Normally, client should receive currently supported version 
//		// list with a special command and use only those versions that are 100 % valid.
//		parserByVersion["v.1.0.000"] = new JSONParser();
		
		parserByVersion["v.2.0.1"] = new CustomJSONParser();
		parserByVersion["v.3.0.1"] = new CustomBinaryParser();
		parserByVersion["v.3.0.2"] = new CustomBinaryParser2();
		parserByVersion.remove("v.2.0.0");
		parserByVersion.remove("v.3.0.0");
	}

	// Methods

}
