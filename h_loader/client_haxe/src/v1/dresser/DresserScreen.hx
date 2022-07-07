package v1.dresser;

import v0.dresser.DresserScreen as DresserScreen0;
import v0.lib.components.Button;
import v0.lib.net.IProtocol;
import v1.net.ICustomProtocol;

/**
 * ColoringScreen.
 * 
 */
class DresserScreen extends DresserScreen0
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
