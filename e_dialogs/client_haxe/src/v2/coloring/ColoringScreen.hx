package v2.coloring;

import v0.coloring.Coloring;
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
	
	private var coloring:Coloring;

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
