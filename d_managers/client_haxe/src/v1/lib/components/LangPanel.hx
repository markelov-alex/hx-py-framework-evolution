package v1.lib.components;

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

//	private var langButtons:Array<LangButton> = [];

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
		var langNames = LangManager.actualLangs;
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
				var button = new LangButton();
				button.lang = langNames[i - hideCount];
				button.skin = buttonSkin;
				addChild(button);
//				langButtons.push(button);
			}
		}
	}

//	override private function unassignSkin():Void
//	{
//		langButtons = [];
//		
//		super.unassignSkin();
//	}
}
