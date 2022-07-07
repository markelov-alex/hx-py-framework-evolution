package v3.menu;

import openfl.events.MouseEvent;
import v3.coloring.ColoringScreen;
import v3.dresser.DresserScreen;
import v3.lib.AudioManager;
import v3.lib.components.Screen;

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

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Listeners
		skin.addEventListener(MouseEvent.CLICK, skin_clickHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(MouseEvent.CLICK, skin_clickHandler);

		super.unassignSkin();
	}

	// Handlers

	private function skin_clickHandler(event:MouseEvent):Void
	{
		// Click on the left or right side of the screen 
		// to reduce or increase sound and music volume
		if (event.stageY < skin.height / 2)
		{
			if (event.stageX < skin.width / 2)
			{
				AudioManager.getInstance().soundVolume -= .1;
			}
			else
			{
				AudioManager.getInstance().soundVolume += .1;
			}
		}
		else
		{
			if (event.stageX < skin.width / 2)
			{
				AudioManager.getInstance().musicVolume -= .1;
			}
			else
			{
				AudioManager.getInstance().musicVolume += .1;
			}
		}
	}
}
