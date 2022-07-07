package v2;

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
import v1.coloring.ColoringModel;
import v1.dresser.DresserModel;

/**
 * Main.
 * 
 * Changes:
 *  - save game state in local SharedObject.
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();
		Log.info('App version: v2');

		// First of all register all class substitution
		var ioc = IoC.getInstance();
		ioc.register(Dresser, v1.dresser.Dresser);
		ioc.register(DresserScreen, v1.dresser.DresserScreen);
		ioc.register(Coloring, v1.coloring.Coloring);
		
		ioc.register(DresserModel, v2.dresser.DresserModel);
		ioc.register(ColoringModel, v2.coloring.ColoringModel);
		ioc.register(Picture, v2.coloring.Picture);

		ioc.load();
		LangManager.getInstance().load();
		AudioManager.getInstance().load();
		
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
