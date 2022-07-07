package v2;

import openfl.display.Sprite;
import v0.lib.AudioManager;
import v0.lib.IoC;
import v0.lib.LangManager;
import v2.lib.components.Screens;
import v2.menu.MenuScreen;

/**
 * Main.
 * 
 * Note: Double click on ConfirmDialog opens ColoringScreen.
 * Note: When testing global dialogs (SettingsDialog.isTestGlobalDialog=true), 
 * ConfirmDialog won't be closed on SettingsDialog close.
 * 
 * Changes:
 *  - only in Screens and Component; for others only version of base class is changed.
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
//		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
