package v5;

import v0.lib.IoC;
import v2.coloring.IColoringProtocol;
import v2.dresser.IDresserProtocol;
import v2.lib.net.IProtocol;
import v2.lib.net.Protocol;

/**
 * Main.
 * 
 * Changes:
 *  - make binary versions of parsers.
 */
class Main extends v4.Main
{
	
	// Settings
	
	// State

	// Init
	
	override private function setUp():Void
	{
		super.setUp();
		
		var ioc = IoC.getInstance();
		ioc.register(IDresserProtocol, v5.dresser.DresserProtocol);
		ioc.register(IColoringProtocol, v5.coloring.ColoringProtocol);
		//ioc.register(ITransport, SocketTransport);
		// For using same transport in all protocols (connect() called in v2.Main)
		ioc.register(Protocol, v5.dresser.DresserProtocol);
		
		// Connect also another type of transport 
		// (dresser and coloring protocols use different types of transport for better testing)
		var protocol2:IProtocol = ioc.getSingleton(IColoringProtocol);
		protocol2.connect(host, port);
	}
}
