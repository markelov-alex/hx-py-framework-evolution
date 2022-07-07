package v2.coloring;

import v2.menu.MenuScreen;
import v1.coloring.Coloring;
import v2.lib.components.Screen;

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
