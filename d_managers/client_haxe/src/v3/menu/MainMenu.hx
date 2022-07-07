package v3.menu;

import openfl.text.TextField;
import openfl.events.MouseEvent;
import v3.lib.components.Button;
import v3.lib.components.Component;
import v3.lib.components.Label;
import v3.lib.components.LangPanel;
import v3.lib.components.MusicToggleButton;
import v3.lib.components.Screen;
import v3.lib.components.Screens;
import v3.lib.components.SoundToggleButton;

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
	private var soundToggleButton2:SoundToggleButton;
	private var musicToggleButton2:MusicToggleButton;
	private var langPanel:LangPanel;
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

		// To test button toggled on change AudioManage state in code or by other button
		soundToggleButton2 = createComponent(SoundToggleButton);
		soundToggleButton2.skinPath = "soundToggleButton2";
		soundToggleButton2.visible = false;
		addChild(soundToggleButton2);
		musicToggleButton2 = createComponent(MusicToggleButton);
		musicToggleButton2.skinPath = "musicToggleButton2";
		musicToggleButton2.visible = false;
		addChild(musicToggleButton2);

		langPanel = createComponent(LangPanel);
		langPanel.skinPath = "langPanel";
		addChild(langPanel);
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
}
