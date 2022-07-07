package v2.menu;

import openfl.events.MouseEvent;
import v1.lib.Log;
import v1.lib.ResourceManager;
import v2.coloring.ColoringScreen;
import v2.dresser.DresserScreen;
import v2.lib.AudioManager;
import v2.lib.components.Screen;

/**
 * MenuScreen.
 * 
 * Note:
 * As button classes aren't chagned, they still use old AudioManager, 
 * so soundVolume does not affect on click sounds.
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
		// because libs are small yet).
		ResourceManager.loadLibrary("game");
		
		// To use another version of a component we are forced 
		// to rewrite completely the class that uses it (like here), 
		// or revert changes that were made in base class 
		// (removeChild(mainMenu); mainMenu = new MainMenu();) 
		// So TODO make class substitution in IoC container and create 
		// all classes through that container
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

		// Listeners
		skin.addEventListener(MouseEvent.CLICK, skin_clickHandler);

		// Test track volume changed after another playMusic() call with same name
		haxe.Timer.delay(function() {
			AudioManager.getInstance().playMusic(music, false, 0, .4);
		}, 2000);
		var isTestPlaylists = false;
		if (isTestPlaylists)
		{
			haxe.Timer.delay(function() {
				Log.debug("Delay0: play longer playlist");
				// Test playlist
				AudioManager.getInstance().playMusic(["click_button", "click_checkbox"], false, 0, 1, -1);
				// Test shorter playlist after a longer one (check playlistIndex reset)
				haxe.Timer.delay(function() {
					Log.debug("Delay1: play shorter playlist");
					AudioManager.getInstance().playMusic(["click_button"], true, 0, 1, 1);
					// (Test playlist cleared and won't loop)
					haxe.Timer.delay(function() {
						Log.debug("Delay2: play just music");
						AudioManager.getInstance().playMusic("click_button", false, 0, 1);
					}, 2000);
				}, 2000);
			}, 4000);
		}
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
