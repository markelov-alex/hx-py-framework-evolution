package v1.menu;

import openfl.events.MouseEvent;
import openfl.text.TextField;
import v1.lib.AudioManager;
import v1.lib.components.Button;
import v1.lib.components.Component;
import v1.lib.components.Label;
import v1.lib.components.LangPanel;
import v1.lib.components.MusicToggleButton;
import v1.lib.components.Screen;
import v1.lib.components.Screens;
import v1.lib.components.SoundToggleButton;

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

		titleLabel = new Label();
		titleLabel.skinPath = "titleText";
		titleLabel.text = "@menu_title";
		addChild(titleLabel);

		soundToggleButton = new SoundToggleButton();
		addChild(soundToggleButton);
		musicToggleButton = new MusicToggleButton();
		addChild(musicToggleButton);

		// To test button toggled on change AudioManage state in code or by other button
		soundToggleButton2 = new SoundToggleButton();
		soundToggleButton2.skinPath = "soundToggleButton2";
		addChild(soundToggleButton2);
		musicToggleButton2 = new MusicToggleButton();
		musicToggleButton2.skinPath = "musicToggleButton2";
		addChild(musicToggleButton2);

		langPanel = new LangPanel();
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

		// DEBUG
		// Listeners
		Std.downcast(titleLabel.skin, TextField).mouseEnabled = true;
		titleLabel.skin.addEventListener(MouseEvent.CLICK, titleLabel_skin_clickHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		titleLabel.skin.removeEventListener(MouseEvent.CLICK, titleLabel_skin_clickHandler);

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

	// DEBUG. For debugging music with isLoop=false (check currentMusic=null after music complete)
	private function titleLabel_skin_clickHandler(event:MouseEvent):Void
	{
		AudioManager.musicLoopCount = 3;
		AudioManager.playMusic("click_button", true);
	}
}
