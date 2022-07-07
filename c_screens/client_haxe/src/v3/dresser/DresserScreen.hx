package v3.dresser;

import v3.dresser.Dresser;
import v3.lib.Screen;

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
	
	private var savedState:Array<Int>;

	// Init

	public function new()
	{
		super();

		assetName = "game:AssetDresserScreen";
		exitScreenClass = MenuScreen;

		dresser = new Dresser();
		dresser.skinPath = dresserPath;
		addChild(dresser);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Load state
		dresser.state = savedState;
	}

	override private function unassignSkin():Void
	{
		// Save state
		savedState = dresser.state;
		
		super.unassignSkin();
	}
}
