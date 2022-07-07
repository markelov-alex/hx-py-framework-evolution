package v2.coloring;

import v1.coloring.Coloring;
import v2.lib.Screen;

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
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		coloring = new Coloring();
		coloring.skin = resolveSkinPath(coloringPath);
		addChild(coloring);
	}

	override private function unassignSkin():Void
	{
		coloring = null;

		super.unassignSkin();
	}

}
