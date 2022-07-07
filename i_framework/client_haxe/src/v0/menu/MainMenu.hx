package v0.menu;

import v0.lib.net.IProtocol;
import v0.net.ICustomProtocol;
import v0.dialogs.SettingsDialog;
import v0.lib.components.Button;
import v0.lib.components.Component;
import v0.lib.components.Label;
import v0.lib.components.LangPanel;
import v0.lib.components.MusicToggleButton;
import v0.lib.components.Screen;
import v0.lib.components.SoundToggleButton;

/**
 * MainMenu.
 * 
 */
class MainMenu extends Component
{
	// Settings

	public var menuButtonPathPrefix = "menuButton";

	public var itemNames = ["Dressing", "Coloring"];
	public var roomNameByItemName:Map<String, String> = new Map();
	public var screenClassByItemName:Map<String, Class<Screen>> = new Map();

	// State
	
	private var titleLabel:Label;
	private var soundToggleButton:SoundToggleButton;
	private var musicToggleButton:MusicToggleButton;
	private var langPanel:LangPanel;
	private var settingsButton:Button;
	private var menuButtons:Array<Button> = [];
	
	private var protocol:ICustomProtocol;

	// Init

	override private function init():Void
	{
		super.init();

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
		
		protocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
	}

	override public function dispose():Void
	{
		super.dispose();
		
		protocol = null;
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Create buttons for each screen
		var buttonSkins = resolveSkinPathPrefix(menuButtonPathPrefix);
		var count = Math.floor(Math.min(itemNames.length, buttonSkins.length));
		for (i in 0...count)
		{
			var button:Button = createComponent(Button);
			button.caption = itemNames[i];
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
		var name = target.caption;
		// Goto room using server
		if (protocol != null)
		{
			var roomName = roomNameByItemName[name];
			if (roomName != null)
			{
				protocol.goto(roomName);
				return;
			}
		}
		// Or just open screen
		if (screens != null)
		{
			var screenClass = screenClassByItemName[name];
			if (screenClass != null)
			{
				screens.open(screenClass);
			}
		}
	}

	private function settingsButton_clickSignalHandler(target:Button):Void
	{
		if (screens != null)
		{
			screens.openDialog(SettingsDialog);
		}
	}
}
