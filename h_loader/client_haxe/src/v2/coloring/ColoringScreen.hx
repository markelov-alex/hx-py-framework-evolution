package v2.coloring;

import v0.lib.net.IProtocol;
import v1.net.ICustomProtocol;
import v2.lib.components.Button;
import v2.lib.components.Component;
import v2.lib.components.Screen;
import v2.menu.MenuScreen;

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
