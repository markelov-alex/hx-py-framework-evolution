package v4.dresser;

import v4.net.CustomJSONParser;

/**
 * DresserProtocol.
 * 
 * Changes:
 *  - use new parser.
 */
class DresserProtocol extends v3.dresser.DresserProtocol
{
	// Settings

	// State

	// Signals

	// Init

	override private function init():Void
	{
		super.init();
		
		parserType = CustomJSONParser;
	}

	// Methods

}
