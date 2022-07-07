package v7.coloring;

import v7.coloring.Coloring;
import v7.lib.components.Component;
import v7.lib.components.Screen;
import v7.menu.MenuScreen;

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

	public function new()
	{
		super();

		assetName = "game:AssetColoringScreen";
		music = "music_coloring";
		exitScreenClass = MenuScreen;

		coloring = createComponent(Coloring);
		coloring.skinPath = coloringPath;
		addChild(coloring);
	}

	// Methods

}
