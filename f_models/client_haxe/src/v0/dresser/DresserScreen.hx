package v0.dresser;

import v0.dresser.Dresser;
import v0.lib.components.Screen;
import v0.menu.MenuScreen;

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
		music = "music_dresser";
		exitScreenClass = MenuScreen;

		dresser = createComponent(Dresser);
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
