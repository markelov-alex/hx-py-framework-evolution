package v2;

import openfl.display.Sprite;
import v2.lib.AudioManager;
import v2.lib.components.Screens;
import v2.lib.LangManager;
import v2.menu.MenuScreen;

/**
 * Changes:
 *  - extract language dicts into external json file,
 *  - resize each screen, not Screens,
 *  - improve AudioManager: add volume,
 *  - to enable inheritence from now on use singletons instead of static classes.
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		LangManager.load();
		AudioManager.getInstance().musicVolume = .2;
		
		// Set up Screens.instance with right version (v2) of Screens instance before 
		// any v1.lib.components.Screens.getInstance() is called. 
		// Since now, whereever in app only v2-Screens will be used.
		var screens = Screens.getInstance();
		// Or the same:
		//var screens = new Screens();
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
