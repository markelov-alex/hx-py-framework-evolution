package v3.coloring;

import v3.coloring.Coloring;
import v3.lib.Screen;

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
		exitScreenClass = MenuScreen;

		coloring = new Coloring();
		coloring.skinPath = coloringPath;
		addChild(coloring);
	}

	// Methods

}
