package v5;

import openfl.display.Sprite;
import v5.coloring.Coloring;
import v5.lib.Signal;

/**
 * Changes:
 *  - use resolveSkinPath() in Component,
 *  - make final: remove dependencies from previous versions.
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		Signal.test();
		
		// If preload="true"
		var mc = new AssetColoringScreen();
		addChild(mc);
		// Logic
		var coloring = new Coloring();
		coloring.skin = mc;
	}
}
