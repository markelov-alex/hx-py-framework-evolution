package v0.net.parser;

import v0.lib.net.parser.JSONParser;
import v0.lib.net.parser.MultiParser;
import v0.net.parser.CustomBinaryParser;
import v0.net.parser.CustomJSONParser;

/**
 * CustomMultiParser.
 * 
 * Changes:
 *  - instantiate all parsers at the very start.
 */
class CustomMultiParser extends MultiParser
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		parserByVersion = [
			"v.1.0.0" => new JSONParser(),
			"v.2.0.0" => new CustomJSONParser(),
			"v.3.0.0" => new CustomBinaryParser(),
		];
	}

	// Methods

}
