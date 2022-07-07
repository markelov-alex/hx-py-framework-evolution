package v1;

import openfl.display.Sprite;
import v1.lib.components.Screens;
import v1.lib.LangManager;
import v1.menu.MenuScreen;

/**
 * Changes:
 *  - group components in separate package,
 *  - extract MainMenu component from MenuScreen,
 *  - language support (in LangManager, LangButton, Button, Label),
 *  - Resizer, StageResizer,
 *  - AudioManager
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		// Note: "@" is not necessary for LangManager, it's only for us.
		LangManager.dictByLang = [
			"en" => [
				"@menu_title" => "Managers",
			],
			"ru" => [
				"@menu_title" => "Менеджеры",
				"Dressing" => "Одевалка",
				"Coloring" => "Раскраска",
			]];
		
		var screens = new Screens();
		screens.skin = this;
		screens.open(MenuScreen);
	}
}
