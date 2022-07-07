package v1.menu;

import v0.lib.components.Button;
import v0.lib.net.IProtocol;
import v0.menu.MainMenu as MainMenu0;
import v1.net.ICustomProtocol;

/**
 * MainMenu.
 * 
 */
class MainMenu extends MainMenu0
{
	// Settings
	
	public var roomNameByItemName:Map<String, String> = new Map();

	// State

	private var protocol:ICustomProtocol;

	// Init

	public function new()
	{
		super();

		protocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
	}

	override public function dispose():Void
	{
		super.dispose();

		protocol = null;
	}

	// Methods

	// Handlers

	override private function menuButton_clickSignalHandler(target:Button):Void
	{
		var name = target.caption;
		// Goto room using server
		if (protocol != null)
		{
			var roomName = roomNameByItemName[name];
			if (roomName != null)
			{
				protocol.goto(roomName);
				return;
			}
		}
		// Or just open screen
		if (screens != null)
		{
			var screenClass = screenClassByName[name];
			if (screenClass != null)
			{
				screens.open(screenClass);
			}
		}
	}
}
