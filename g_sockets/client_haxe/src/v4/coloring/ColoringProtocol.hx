package v4.coloring;

import v4.net.CustomJSONParser;

/**
 * ColoringProtocol.
 * 
 * Changes:
 *  - use new parser.
 */
class ColoringProtocol extends v3.coloring.ColoringProtocol
{
	// Settings

	// State
	
	// Init

	override private function init():Void
	{
		super.init();

		parserType = CustomJSONParser;
	}

	// Methods
}
