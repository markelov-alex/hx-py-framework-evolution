package v0.lib.components;

import v0.lib.components.Button;
import v0.lib.components.Component;
import v0.lib.components.Resizer.StageResizer;

/**
 * Screen.
 * 
 */
class Screen extends Component
{
	// Settings
	
	public var music:String;
	
	public var closeButtonPath:String = "closeButton";
	public var stretchBackgroundPath:String = "background";
	
	public var exitScreenClass:Class<Screen> = null;

	// State
	
	private var closeButton:Button;
	private var resizer:StageResizer;
		
	// Init

	override private function init():Void
	{
		super.init();

		closeButton = createComponent(Button);
		closeButton.skinPath = closeButtonPath;
		// Listeners
		closeButton.clickSignal.add(closeButton_clickSignalHandler);
		addChild(closeButton);

		resizer = createComponent(StageResizer);
		resizer.stretchBackgroundPath = stretchBackgroundPath;
		addChild(resizer);
	}

	override public function dispose():Void
	{
		// Unassigning child components is not necessary as they will be garbage collected anyway
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
		
		audioManager.playMusic(music);
	}

	override private function unassignSkin():Void
	{
		audioManager.stopMusic(music);
		
		super.unassignSkin();
	}

	// Handlers
	
	private function closeButton_clickSignalHandler(target:Button):Void
	{
		if (screens != null)
		{
			screens.open(exitScreenClass);
		}
	}
}
