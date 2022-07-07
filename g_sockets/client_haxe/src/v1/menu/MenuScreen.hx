package v1.menu;

import v0.lib.components.Screen;
import v1.coloring.ColoringScreen;
import v1.dresser.DresserScreen;

/**
 * MenuScreen.
 * 
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
		
		// "menu" library is preloaded, and loading of "game" library 
		// should be started just after menu displayed, to do not wait 
		// after clicking the buttons (practically, we don't wait anyway 
		// because libs are small yet).
		resourceManager.loadLibrary("game");
		
		mainMenu = createComponent(MainMenu);
		mainMenu.screenClassByName = [
			"Dressing" => DresserScreen,
			"Coloring" => ColoringScreen,
		];
		addChild(mainMenu);
	}

	// Methods

}
