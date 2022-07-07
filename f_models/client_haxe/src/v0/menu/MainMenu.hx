package v0.menu;

import v0.dialogs.SettingsDialog;
import v0.lib.components.Button;
import v0.lib.components.Component;
import v0.lib.components.Label;
import v0.lib.components.LangPanel;
import v0.lib.components.MusicToggleButton;
import v0.lib.components.Screen;
import v0.lib.components.Screens;
import v0.lib.components.SoundToggleButton;

/**
 * MainMenu.
 * 
 */
class MainMenu extends Component
{
	// Settings

	public var menuButtonPathPrefix = "menuButton";

	public var screenNames = ["Dressing", "Coloring"];
	public var screenClassByName:Map<String, Class<Screen>> = new Map();

	// State

	private var titleLabel:Label;
	private var soundToggleButton:SoundToggleButton;
	private var musicToggleButton:MusicToggleButton;
	private var langPanel:LangPanel;
	private var settingsButton:Button;
	private var menuButtons:Array<Button> = [];

	// Init

	public function new()
	{
		super();

		titleLabel = createComponent(Label);
		titleLabel.skinPath = "titleText";
		titleLabel.text = "@menu_title";
		addChild(titleLabel);

		soundToggleButton = createComponent(SoundToggleButton);
		addChild(soundToggleButton);
		musicToggleButton = createComponent(MusicToggleButton);
		addChild(musicToggleButton);
		
		langPanel = createComponent(LangPanel);
		langPanel.skinPath = "langPanel";
		addChild(langPanel);

		settingsButton = createComponent(Button);
		settingsButton.skinPath = "settingsButton";
		// Listeners
		settingsButton.clickSignal.add(settingsButton_clickSignalHandler);
		addChild(settingsButton);
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
			var button = createComponent(Button);
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
		Screens.getInstance().open(screenClass);
	}

	private function settingsButton_clickSignalHandler(target:Button):Void
	{
		var screens = Screens.getInstance();
		var dialog = screens.openDialog(SettingsDialog);
	}
}
