package v2;

import openfl.display.Sprite;
import openfl.utils.Assets;

class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		// If preload="true"
		var mc = new Dresser();
		addChild(mc);
	}
}
