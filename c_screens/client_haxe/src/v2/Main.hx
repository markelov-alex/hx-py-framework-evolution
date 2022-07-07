package v2;

import openfl.display.Sprite;
import v2.lib.Screens;

/**
 * Changes:
 *  - create Screens component for managing screens in organized way,
 *  - create skin by assetName when adding to parent component.
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		var screens = new Screens();
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
