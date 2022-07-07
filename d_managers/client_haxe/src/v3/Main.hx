package v3;

import openfl.display.Sprite;
import v3.lib.AudioManager;
import v3.lib.components.Screens;
import v3.lib.LangManager;
import v3.menu.MenuScreen;

/**
 * Main.
 * 
 * In v2 we saw, how difficult it is to make every small change in 
 * any class: we have to override every class that use it and change 
 * old class with its subclass. As a result application turns to mess. 
 * So, we create IoC container (class IoC), and will instantiate 
 * all classes with it. To make it also available for inheritance we'll 
 * create it as singleton, not as static class.
 * 
 * Changes:
 *  - create IoC container, use it for all instantiations in all classes,
 *  - convert all managers from static classes to singletons to make 
 *  them extendable (using IoC container).
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		LangManager.getInstance().load();
		// To test that infinite loop is really infinite (on short track)
		AudioManager.getInstance().musicLoopCount = 5;
		
		var screens = Screens.getInstance();
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
