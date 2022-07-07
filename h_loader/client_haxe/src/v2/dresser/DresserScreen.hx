package v2.dresser;

import v0.lib.net.IProtocol;
import v1.net.ICustomProtocol;
import v2.lib.components.Button;
import v2.lib.components.Component;
import v2.lib.components.Screen;
import v2.menu.MenuScreen;

/**
 * DresserScreen.
 * 
 */
class DresserScreen extends Screen
{
	// Settings
	
	public var dresserPath = "";

	// State
	
	private var dresser:Component;

	// Init

	override private function init():Void
	{
		super.init();
		
		assetName = "game:AssetDresserScreen";
		music = "music_dresser";
		exitScreenClass = MenuScreen;

		dresser = createComponent(Dresser);
		dresser.skinPath = dresserPath;
		addChild(dresser);
	}

	// Methods

	// Handlers

	override private function closeButton_clickSignalHandler(target:Button):Void
	{
		var protocol:ICustomProtocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
		protocol.goto("lobby");
	}
}
