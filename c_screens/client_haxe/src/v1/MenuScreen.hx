package v1;

import v1.coloring.ColoringScreen;
import v1.dresser.DresserScreen;
import v1.lib.Button;
import v1.lib.Screen;

/**
 * MenuScreen.
 * 
 */
class MenuScreen extends Screen
{
	// Settings
	
	public var menuButtonPathPrefix = "menuButton";

	public var screenNames = ["Dressing", "Coloring"];
	public var screenClassByName:Map<String, Class<Screen>> = [
		"Dressing" => DresserScreen,
		"Coloring" => ColoringScreen,
	];
	
	// State
	
	private var menuButtons:Array<Button> = [];

	// Init

	public function new()
	{
		// Won't work if default value is set in class definition
		assetName = "menu:AssetMenuScreen";
		super();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Create buttons for each screen
		var buttonSkins = resolveSkinPathPrefix(menuButtonPathPrefix);
		var count = Math.floor(Math.min(screenNames.length, buttonSkins.length));
		for (i in 0...count)
		{
			var button = new Button();
			button.caption = screenNames[i];
			button.data = screenClassByName[screenNames[i]];
			button.skin = buttonSkins[i];
			addChild(button);
			menuButtons.push(button);
			// Listeners
			button.clickSignal.add(menuButton_clickSignalHandler);
		}
		// Hide others
		for (i => buttonSkin in buttonSkins)
		{
			buttonSkin.visible = i < count;
		}
	}

	override private function unassignSkin():Void
	{
		for (button in menuButtons)
		{
			// Listeners
			button.clickSignal.remove(menuButton_clickSignalHandler);
		}
		menuButtons = [];
		
		super.unassignSkin();
	}

	// Handlers
	
	private function menuButton_clickSignalHandler(target:Button):Void
	{
		var screenClass = cast target.data;
		open(screenClass);
	}
}
