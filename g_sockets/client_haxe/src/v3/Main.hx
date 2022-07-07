package v3;

import v0.lib.IoC;
import v2.coloring.IColoringProtocol;
import v2.dresser.IDresserProtocol;
import v2.lib.net.Protocol;

/**
 * Main.
 * 
 * Changes:
 *  - finish Protocol extracting Parser and Transport.
 */
class Main extends v2.Main
{
	// Settings
	
	// State

	// Init
	
	override private function setUp():Void
	{
		super.setUp();
		
		var ioc = IoC.getInstance();
		ioc.register(IDresserProtocol, v3.dresser.DresserProtocol);
		ioc.register(IColoringProtocol, v3.coloring.ColoringProtocol);
		// For using same transport in all protocols (connect() called in v2.Main)
		ioc.register(Protocol, v3.lib.net.JSONSocketProtocol);
	}
}
