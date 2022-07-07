package v4;

import v0.lib.IoC;
import v2.coloring.IColoringProtocol;
import v2.dresser.IDresserProtocol;
import v2.lib.net.Protocol;

/**
 * Main.
 * 
 * Changes:
 *  - make shorter JSON protocol (using lists instead of dicts).
 */
class Main extends v3.Main
{
	// Settings
	
	// State

	// Init
	
	override private function setUp():Void
	{
		super.setUp();
		
		var ioc = IoC.getInstance();
		ioc.register(IDresserProtocol, v4.dresser.DresserProtocol);
		ioc.register(IColoringProtocol, v4.coloring.ColoringProtocol);
		//ioc.register(ITransport, SocketTransport);
		// For using same transport in all protocols (connect() called in v2.Main)
		ioc.register(Protocol, v4.dresser.DresserProtocol);
	}
}
