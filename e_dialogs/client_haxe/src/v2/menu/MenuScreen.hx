package v2.menu;

import openfl.events.MouseEvent;
import v0.lib.AudioManager;
import v2.coloring.ColoringScreen;
import v2.dresser.DresserScreen;
import v2.lib.components.Screen;

/**
 * MenuScreen.
 * 
 * Changes:
 *  - remove changing sound/music volume by clicking on different 
 *  parts of the screen, as we now have  
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
