package v4;

import openfl.display.Sprite;
import v3.lib.AudioManager;
import v3.lib.components.LangButton;
import v3.lib.components.Screens;
import v3.lib.LangManager;
import v3.lib.ResourceManager;
import v3.menu.MenuScreen;
import v4.lib.IoC;

/**
 * Main.
 * 
 * Changes:
 *  - Testing IoC (class substitution) extending AudioManager, LangManager, etc,
 *  - add AudioManager and tracks set up with external file,
 *  - set up LangManager by data in external file,
 *  - add instance configs to IoC, load them from external file, 
 *  - save current state of managers in SharedObject.
 */
class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		// First of all register all class substitution
		var ioc = new IoC();
		// (New classes will be instantiated instead of the old ones)
		ioc.register(LangManager, v4.lib.LangManager);
		ioc.register(AudioManager, v4.lib.AudioManager);
		ioc.register(LangButton, v4.lib.components.LangButton);
		var resourceManager = ResourceManager.getInstance();
		resourceManager.assetNameByName["config.yml"] = "assets/config.yml";
		resourceManager.assetNameByName["config.json"] = "assets/config.json";
		ioc.load();
		ioc.load("config.json");

		// Lang
		var langManager = LangManager.getInstance();
		// (Now multiple files could be loaded)
		langManager.load("lang.yaml");
		langManager.load("lang.json");
		// Audio
		var audioManager = Std.downcast(AudioManager.getInstance(), v4.lib.AudioManager);
		resourceManager.assetNameByName["audio.yml"] = "assets/audio.yml";
		resourceManager.assetNameByName["audio.json"] = "assets/audio.json";
		audioManager.load(); // "audio.yml"
		audioManager.load("audio.json");
		
		// Screens
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);
		
//		Timer.delay(function () {audioManager.stopMusic("music_menu2");}, 5000);
//		Timer.delay(function () {audioManager.stopMusic(["click_button","click_checkbox","click_checkbox2","music_menu"]);}, 5000);
	}
}
