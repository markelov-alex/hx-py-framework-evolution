package v6.net;

import v3.lib.net.parser.JSONParser;
import v4.net.CustomJSONParser;
import v5.net.CustomBinaryParser;
import v6.lib.net.parser.AutoMultiParser;

/**
 * ColoringMultiParser.
 * 
 */
class CustomMultiParser extends AutoMultiParser
{
	// Settings

	// State

	// Init

	override private function init():Void
	{
		defaultVersion = "v.1.0.0";
		//defaultVersion = "v.3.0.0";//temp
		parserByVersion = [
			// Instance
			"v.1.0.0" => new JSONParser(),
			// Factory
			"v.2.0.0" => function () { return new CustomJSONParser(); },
			// Class
			"v.3.0.0" => CustomBinaryParser,
		];
		
		super.init();
	}

	// Methods

}
