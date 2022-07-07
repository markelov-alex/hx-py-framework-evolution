package v1.lib.dresser;

import v1.framework.ui.Button;
import v1.framework.ui.Component;
import v1.framework.ui.Screen;
import v1.framework.net.IProtocol;
import v1.app.menu.MenuScreen;
import v1.app.net.ICustomProtocol;

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
