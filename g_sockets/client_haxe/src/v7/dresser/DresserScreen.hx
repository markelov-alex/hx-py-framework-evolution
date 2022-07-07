package v7.dresser;

import v7.dresser.Dresser;
import v7.lib.components.Component;
import v7.lib.components.Screen;
import v7.menu.MenuScreen;

/**
 * DresserScreen.
 * 
 */
class DresserScreen extends Screen
{
	// Settings
	
	public var dresserPath = "";

	// State
	
	private var dresser:Component;

	// Init

	public function new()
	{
		super();

		assetName = "game:AssetDresserScreen";
		music = "music_dresser";
		exitScreenClass = MenuScreen;

		dresser = createComponent(Dresser);
		dresser.skinPath = dresserPath;
		addChild(dresser);
	}

	// Methods

}
