package v4;

import openfl.display.Sprite;
import v3.coloring.Coloring;

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
		var coloring = new Coloring();
		coloring.skin = mc;
	}
}
