package v0.lib.components;

/**
 * LangPanel.
 * 
 */
class LangPanel extends Component
{
	// Settings
	
	public var langButtonPathPrefix = "langButton";
	public var align = "right";

	// State

	private var langManager = LangManager.getInstance();

	public var lang(get, set):String;
	public function get_lang():String
	{
		return langManager != null ? langManager.currentLang : null;
	}
	public function set_lang(value:String):String
	{
		return langManager != null ? (langManager.currentLang = value) : null;
	}

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Create lang buttons according to given buttons in skin
		var langNames = LangManager.getInstance().actualLangs;
		var buttonSkins = resolveSkinPathPrefix(langButtonPathPrefix);
		var hideCount = buttonSkins.length - langNames.length;
		if (hideCount < 0)
		{
			hideCount = 0;
		}
		var isAlignRight = align == "right";
		for (i => buttonSkin in buttonSkins)
		{
			buttonSkin.visible = !isAlignRight || i >= hideCount;
			if (buttonSkin.visible)
			{
				var button:LangButton = createComponent(LangButton);
				button.lang = langNames[i - hideCount];
				button.skin = buttonSkin;
				addChild(button);
			}
		}
	}
}
