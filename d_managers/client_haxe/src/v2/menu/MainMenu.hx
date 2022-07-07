package v2.menu;

import v2.lib.AudioManager;
import openfl.events.MouseEvent;

/**
 * MainMenu.
 * 
 */
class MainMenu extends v1.menu.MainMenu
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		soundToggleButton2.visible = false;
		musicToggleButton2.visible = false;
	}

	// Methods

	// Handlers
	
	override private function titleLabel_skin_clickHandler(event:MouseEvent):Void
	{
		// For testing soundVolume
		AudioManager.getInstance().stopMusic();
		AudioManager.getInstance().playSound("music_dresser");
	}
}
