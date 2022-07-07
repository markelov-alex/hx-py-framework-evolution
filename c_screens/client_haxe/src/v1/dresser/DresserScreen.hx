package v1.dresser;

import v1.lib.Screen;

/**
 * DresserScreen.
 * 
 */
class DresserScreen extends Screen
{
	// Settings
	
	public var dresserPath = "";

	// State
	
	private var dresser:Dresser;

	// Init

	public function new()
	{
		// Won't work if default value is set in class definition
		assetName = "game:AssetDresserScreen";
		exitScreenClass = MenuScreen;
		super();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		dresser = new Dresser();
		dresser.skin = resolveSkinPath(dresserPath);
		addChild(dresser);
	}

	override private function unassignSkin():Void
	{
		dresser = null;

		super.unassignSkin();
	}

}
