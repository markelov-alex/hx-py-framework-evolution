package v3;

import openfl.display.Sprite;

class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		// If preload="true"
		var mc = new AssetDresserScreen();
		addChild(mc);
		// Logic
		var dresser = new Dresser(mc);
	}
}
