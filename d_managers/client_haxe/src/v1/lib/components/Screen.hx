package v1.lib.components;

import v1.lib.components.Button;
import v1.lib.components.Component;

/**
 * Screen.
 * 
 * Changes:
 *  - remove screens property, use Screens.getInstance().
 */
class Screen extends Component
{
	// Settings
	
	public var music:String;
	
	public var closeButtonPath:String = "closeButton";
	
	public var exitScreenClass:Class<Screen> = null;

	// State
	
	private var closeButton:Button;

	// Init

	public function new()
	{
		super();

		closeButton = new Button();
		closeButton.skinPath = closeButtonPath;
		// Listeners
		closeButton.clickSignal.add(closeButton_clickSignalHandler);
		addChild(closeButton);
	}

	override public function dispose():Void
	{
		if (closeButton != null)
		{
			// Listeners
			closeButton.clickSignal.remove(closeButton_clickSignalHandler);
			closeButton = null;
		}
		
		super.dispose();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		AudioManager.playMusic(music);
	}

	override private function unassignSkin():Void
	{
		AudioManager.stopMusic(music);
		
		super.unassignSkin();
	}

	// Handlers
	
	private function closeButton_clickSignalHandler(target:Button):Void
	{
		Screens.getInstance().open(exitScreenClass);
	}
}
