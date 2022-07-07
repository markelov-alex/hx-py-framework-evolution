package v1.coloring;

import v0.coloring.ColoringScreen as ColoringScreen0;
import v0.lib.components.Button;
import v0.lib.net.IProtocol;
import v1.net.ICustomProtocol;

/**
 * ColoringScreen.
 * 
 */
class ColoringScreen extends ColoringScreen0
{
	// Settings

	// State

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	// Handlers

	override private function closeButton_clickSignalHandler(target:Button):Void
	{
		var protocol:ICustomProtocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
		protocol.goto("lobby");
	}
}
