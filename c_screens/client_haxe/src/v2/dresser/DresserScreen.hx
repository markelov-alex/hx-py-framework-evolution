package v2.dresser;

import v1.dresser.Dresser;
import v2.lib.Screen;

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
		super();

		assetName = "game:AssetDresserScreen";
		exitScreenClass = MenuScreen;
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
