package v6;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v0.lib.IoC;
import v2.coloring.IColoringProtocol;
import v2.dresser.IDresserProtocol;
import v2.lib.net.IProtocol;
import v2.lib.net.Protocol;
import v6.coloring.ColoringProtocol;
import v6.net.CustomMultiParser;

/**
 * Main.
 * 
 * Changes:
 *  - MultiParser, allowing controller switching.
 */
class Main extends v4.Main
{
	
	// Settings
	
	// State
	
	private var controller:ColoringProtocol;
	private var versions:Array<String>;

	// Init
	
	override private function setUp():Void
	{
		super.setUp();
		
		var ioc = IoC.getInstance();
		ioc.register(IDresserProtocol, v6.dresser.DresserProtocol);
		ioc.register(IColoringProtocol, v6.coloring.ColoringProtocol);
		//ioc.register(ITransport, SocketTransport);
		// For using same transport in all protocols (connect() called in v2.Main)
		ioc.register(Protocol, v6.dresser.DresserProtocol);
		
		// Connect also another type of transport 
		// (dresser and coloring protocols use different types of transport for better testing)
		var controller2:IProtocol = ioc.getSingleton(IColoringProtocol);
		controller2.connect(host, port);
		
		// For switching controller version
		// (Get versions)
		controller = cast controller2;
		var parser = new CustomMultiParser();
		versions = [for (v in parser.parserByVersion.keys()) v];
		versions.sort(function (a, b) { return a < b ? -1 : (a > b ? 1 : 0); });
		// Listeners
		stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
	}
	
	// Handlers

	private function stage_keyUpHandler(event:KeyboardEvent):Void
	{
		if (event.keyCode >= Keyboard.NUMBER_1 && event.keyCode <= Keyboard.NUMBER_9)
		{
			var index = event.keyCode - Keyboard.NUMBER_1;
			var version = versions[index];
			controller.changeVersion(version);
		}
	}
}
