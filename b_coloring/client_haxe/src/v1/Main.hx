package v1;

import openfl.display.Sprite;

class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		// If preload="true"
		var mc = new AssetColoringScreen();
		addChild(mc);
		// Logic
		var coloring = new Coloring(mc);
	}
}
