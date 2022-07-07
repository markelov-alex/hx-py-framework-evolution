package v0;

import openfl.display.Sprite;
import v0.lib.AudioManager;
import v0.lib.components.Screens;
import v0.lib.IoC;
import v0.lib.LangManager;
import v0.menu.MenuScreen;

/**
 * Main.
 * 
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		// First of all register all class substitution
		var ioc = IoC.getInstance();
		ioc.load();
		LangManager.getInstance().load();
		AudioManager.getInstance().load();
		
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
