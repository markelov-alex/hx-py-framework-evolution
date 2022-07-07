package v9.net.parser;

import v7.lib.net.parser.JSONParser;
import v7.net.parser.CustomBinaryParser;
import v7.net.parser.CustomJSONParser;
import v9.lib.net.parser.MultiParser;

/**
 * CustomMultiParser.
 * 
 * For dresser, coloring and similar games.
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
			// Instance
			"v.1.0.0" => new JSONParser(),
			// Factory
			"v.2.0.0" => function () { return new CustomJSONParser(); },
			// Class
			"v.3.0.0" => CustomBinaryParser,
		];
	}

	// Methods

}
