package v1.lib.coloring;

import v1.framework.ui.Button;
import v1.framework.ui.Component;
import v1.framework.ui.Screen;
import v1.framework.net.IProtocol;
import v1.app.menu.MenuScreen;
import v1.app.net.ICustomProtocol;

/**
 * ColoringScreen.
 * 
 */
class ColoringScreen extends Screen
{
	// Settings
	
	public var coloringPath = "";

	// State
	
	private var coloring:Component;

	// Init

	override private function init():Void
	{
		super.init();
		
		assetName = "game:AssetColoringScreen";
		music = "music_coloring";
		exitScreenClass = MenuScreen;

		coloring = createComponent(Coloring);
		coloring.skinPath = coloringPath;
		addChild(coloring);
	}

	// Methods

	// Handlers

	override private function closeButton_clickSignalHandler(target:Button):Void
	{
		var protocol:ICustomProtocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
		protocol.goto("lobby");
	}
}
