package v5;

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
import v3.dresser.DresserModel;

/**
 * Main.
 * 
 * Changes:
 *  - extract Request from StorageService.
 */
class Main extends Sprite
{
	private var ioc:IoC;
	
	public function new()
	{
		super();
		Log.info('App version: v5');

		// First of all register all class substitution
		ioc = IoC.getInstance();
		initialize();

		ioc.load();
		LangManager.getInstance().load();
		AudioManager.getInstance().load();
		
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);
	}
	
	private function initialize():Void
	{
		ioc.register(DresserScreen, v1.dresser.DresserScreen);
		ioc.register(Dresser, v3.dresser.Dresser);
		ioc.register(Coloring, v1.coloring.Coloring);
		ioc.register(Picture, v3.coloring.Picture);

		ioc.register(DresserModel, v5.dresser.DresserModel);
		ioc.register(ColoringModel, v5.coloring.ColoringModel);
	}
}
