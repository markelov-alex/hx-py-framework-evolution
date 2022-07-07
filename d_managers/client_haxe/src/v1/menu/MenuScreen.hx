package v1.menu;

import v1.coloring.ColoringScreen;
import v1.dresser.DresserScreen;
import v1.lib.ResourceManager;
import v2.lib.AudioManager;
import v2.lib.components.Screen;

/**
 * MenuScreen.
 * 
 * Changes:
 *  - extract all functianality to MainMenu to do not copy it in v2 and other versions,
 *  - Assets -> ResourceManager.
 */
class MenuScreen extends Screen
{
	// Settings
	
	// State
	
	private var mainMenu:MainMenu;

	// Init

	public function new()
	{
		super();

		assetName = "menu:AssetMenuScreen";
		music = "music_menu";
		//music = "click_button"; // Test isLoop=true
		
		// "menu" library is preloaded, and loading of "game" library 
		// should be started just after menu displayed, to do not wait 
		// after clicking the buttons (practically, we don't wait anyway 
		// because libs are small yet.)
		ResourceManager.loadLibrary("game");
		
		mainMenu = new MainMenu();
		mainMenu.screenClassByName = [
			"Dressing" => DresserScreen,
			"Coloring" => ColoringScreen,
		];
		addChild(mainMenu);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Test initial volume saved after music turned off and then on again
		AudioManager.getInstance().playMusic(music, false, 0, .3);
	}
}
