package v1.menu;

import v0.lib.components.Button;
import v0.lib.components.Screens;
import v1.dialogs.SettingsDialog;

/**
 * MainMenu.
 * 
 */
class MainMenu extends v0.menu.MainMenu
{
	// Settings

	// State

	private var settingsButton:Button;

	// Init

	public function new()
	{
		super();

		settingsButton = createComponent(Button);
		settingsButton.skinPath = "settingsButton";
		// Listeners
		settingsButton.clickSignal.add(settingsButton_clickSignalHandler);
		addChild(settingsButton);
	}

	// Methods

	// Handlers

	private function settingsButton_clickSignalHandler(target:Button):Void
	{
		var screens:v1.lib.components.Screens = Std.downcast(Screens.getInstance(), v1.lib.components.Screens);
		var dialog = screens.openDialog(SettingsDialog);
	}
}
