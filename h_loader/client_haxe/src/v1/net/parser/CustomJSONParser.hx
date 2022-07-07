package v1.net.parser;

import v0.net.parser.CustomJSONParser as CustomJSONParser0;

/**
 * CustomJSONParser.
 * 
 * For dresser, coloring and similar games.
 */
class CustomJSONParser extends CustomJSONParser0
{
	// Settings

	// State
	
	// Init

	public function new()
	{
		super();

		converter.codeField = "code";
		converter.fieldsByCode["goto"] = ["code", "name", "data"];
	}

	// Methods

}
