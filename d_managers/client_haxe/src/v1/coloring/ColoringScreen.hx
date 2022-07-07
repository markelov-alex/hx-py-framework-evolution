package v1.coloring;

import v1.coloring.Coloring;
import v1.lib.components.Screen;
import v1.menu.MenuScreen;

/**
 * ColoringScreen.
 * 
 */
class ColoringScreen extends Screen
{
	// Settings
	
	public var coloringPath = "";

	// State
	
	private var coloring:Coloring;

	// Init

	public function new()
	{
		super();

		assetName = "game:AssetColoringScreen";
		music = "music_coloring";
		exitScreenClass = MenuScreen;

		coloring = new Coloring();
		coloring.skinPath = coloringPath;
		addChild(coloring);
	}

	// Methods

}
