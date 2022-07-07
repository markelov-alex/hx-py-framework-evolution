package v3;

import openfl.display.Sprite;
import v3.lib.Screens;

/**
 * Changes:
 *  - move assetName to Component,
 *  - add skinPath property to Component,
 *  - set skin by skinPath when adding to parent component,
 *  - create components in constructor, not in assignSkin() to enable reusing them,
 *  - add dispose() for clearing up children components created in constructor, 
 *    (though clearing references to these children is not necessary),
 *  - add screen components reusing (Screens.isReuseComponents), 
 *    thus game state retains unchanged,
 *  - use ResourceManager instead of Assets,
 *  - create Log interface class.
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
