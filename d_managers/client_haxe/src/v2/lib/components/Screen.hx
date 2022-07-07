package v2.lib.components;

import v1.lib.components.Resizer;
import v2.lib.components.StageResizer;

/**
 * Screen.
 * 
 */
class Screen extends v1.lib.components.Screen
{
	// Settings
	
	public var stretchBackgroundPath:String = "background";

	// State

	private var resizer:StageResizer;

	// Init

	public function new()
	{
		super();

		resizer = new StageResizer();
		resizer.stretchBackgroundPath = stretchBackgroundPath;
		addChild(resizer);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// (Use new version of AudioManager)
		v1.lib.AudioManager.stopMusic(music);
		AudioManager.getInstance().playMusic(music);
	}

	override private function unassignSkin():Void
	{
		// (Use new version of AudioManager)
		AudioManager.getInstance().stopMusic(music);
		
		super.unassignSkin();
	}
}
