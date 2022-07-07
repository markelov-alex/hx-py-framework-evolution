package v2.menu;

import v2.coloring.ColoringScreen;
import v2.dresser.DresserScreen;
import v2.lib.components.Screen;

/**
 * MenuScreen.
 * 
 * Changes:
 *  - remove AudioManager.getInstance(),
 *  - move resourceManager.loadLibrary() to assignSkin();
 */
class MenuScreen extends Screen
{
	// Settings
	
	// State
	
	private var mainMenu:MainMenu;

	// Init

	override private function init():Void
	{
		super.init();
		
		assetName = "menu:AssetMenuScreen";
		music = "music_menu";
		
		mainMenu = createComponent(MainMenu);
		mainMenu.itemNames = [
			"Dressing 1", "Dressing 2", "Dressing 3", 
			"Coloring 1", "Coloring 2", "Coloring 3"];
		mainMenu.roomNameByItemName = [
			"Dressing 1" => "dresser1",
			"Dressing 2" => "dresser2",
			"Dressing 3" => "dresser3",
			"Coloring 1" => "coloring1",
			"Coloring 2" => "coloring2",
			"Coloring 3" => "coloring3",
		];
		mainMenu.screenClassByItemName = [
			"Dressing" => DresserScreen,
			"Coloring" => ColoringScreen,
		];
		addChild(mainMenu);
	}

	// Methods

}
