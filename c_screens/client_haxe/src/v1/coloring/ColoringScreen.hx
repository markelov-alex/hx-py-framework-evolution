package v1.coloring;

import v1.lib.Screen;

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
		// Won't work if default value is set in class definition
		assetName = "game:AssetColoringScreen";
		exitScreenClass = MenuScreen;
		super();
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
