package v3.lib;

import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import v3.lib.Button;
import v3.lib.Component;

/**
 * Screen.
 * 
 * Changes:
 *  - move assetName and readySignal to Component.
 */
class Screen extends Component
{
	// Settings
	
	public var closeButtonPath:String = "closeButton";
	
	public var exitScreenClass:Class<Screen> = null;

	// State
	
	private var closeButton:Button;
	
	private var screens(get, null):Screens;
	private function get_screens():Screens
	{
		return Std.downcast(parent, Screens);
	}

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
		super.dispose();

		if (closeButton != null)
		{
			// Listeners
			closeButton.clickSignal.remove(closeButton_clickSignalHandler);
			closeButton = null;
		}
	}

	// Methods
	
	// Handlers
	
	private function closeButton_clickSignalHandler(target:Button):Void
	{
		screens.open(exitScreenClass);
	}
}
