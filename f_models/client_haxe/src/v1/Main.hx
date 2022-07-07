package v1;

import openfl.display.Sprite;
import v0.coloring.Coloring;
import v0.coloring.Picture;
import v0.dresser.Dresser;
import v0.dresser.DresserScreen;
import v0.lib.AudioManager;
import v0.lib.components.Screens;
import v0.lib.IoC;
import v0.lib.LangManager;
import v0.lib.Log;
import v0.menu.MenuScreen;

/**
 * Main.
 * 
 * Changes:
 *  - add models to store state of screens and games (as singletons in ioc), 
 *    destroy screens (with their state) on close.
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();
		Log.info('App version: v1');

		// First of all register all class substitution
		var ioc = IoC.getInstance();
		ioc.load();
		LangManager.getInstance().load();
		AudioManager.getInstance().load();
		
		ioc.register(Dresser, v1.dresser.Dresser);
		ioc.register(DresserScreen, v1.dresser.DresserScreen);
		ioc.register(Coloring, v1.coloring.Coloring);
		ioc.register(Picture, v1.coloring.Picture);
		
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
