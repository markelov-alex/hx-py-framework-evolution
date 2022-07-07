package v1.framework.ui.lang;

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

	public var language(get, set):String;
	public function get_language():String
	{
		return lang != null ? lang.currentLang : null;
	}
	public function set_language(value:String):String
	{
		return lang != null ? (lang.currentLang = value) : null;
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
		var langNames = lang.actualLangs;
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
				button.language = langNames[i - hideCount];
				button.skin = buttonSkin;
				addChild(button);
			}
		}
	}
}
