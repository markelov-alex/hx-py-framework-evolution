package v1;

import openfl.display.Sprite;
import v0.lib.AudioManager;
import v0.lib.components.Screens;
import v0.lib.IoC;
import v0.lib.LangManager;
import v0.menu.MainMenu;
import v0.menu.MenuScreen;

/**
 * Main.
 * 
 * Note: Double click on ConfirmDialog opens ColoringScreen, which is 
 * currently not working because of ModalControl (will be fixed in v2).
 * Note: Can not open ConfirmDialog on click outside of SettingsDialog, 
 * because the click by which we close ConfirmDialog, the same click 
 * is used via ClickOutside to open another ConfirmDialog. So this 
 * dialog become unclosable.
 * 
 * Changes:
 *  - first attempt to implement dialogs: try to do modality and 
 *  close-on-click-outside inside Dialog (with ModalControl and ClickOutside 
 *  correspondently), which leads us to bugs, that are unresolveable within 
 *  such paradigm. They'll be fixed in v2 with implementing these functionalities 
 *  inside Screens.
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
		
		ioc.register(Screens, v1.lib.components.Screens);
		ioc.register(MainMenu, v1.menu.MainMenu);
		
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
