package v3.lib;

import v2.lib.Component;
import openfl.events.MouseEvent;

/**
 * Button.
 * 
 */
class Button extends Component
{
	// Settings

	// State
	
	public var isEnabled(default, set):Bool = true;
	public function set_isEnabled(value:Bool):Bool
	{
		if (isEnabled != value)
		{
			isEnabled = value;
			refreshEnabled();
		}
		return value;
	}
	
	public var useHandCursor(default, set):Bool = true;
	public function set_useHandCursor(value:Bool):Bool
	{
		if (useHandCursor != value)
		{
			useHandCursor = value;
			refreshHandCursor();
		}
		return value;
	}
	
	// Signals

	public var clickSignal(default, null) = new Signal<Button>();

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		refreshEnabled();
		
		if (interactiveObject != null)
		{
			// Listeners
			interactiveObject.addEventListener(MouseEvent.CLICK, interactiveObject_clickHandler);
		}
	}

	override private function unassignSkin():Void
	{
		if (interactiveObject != null)
		{
			// Listeners
			interactiveObject.removeEventListener(MouseEvent.CLICK, interactiveObject_clickHandler);
		}

		super.unassignSkin();
	}

	private function refreshEnabled():Void
	{
		if (interactiveObject != null)
		{
			interactiveObject.mouseEnabled = isEnabled;
		}
		if (simpleButton != null)
		{
			simpleButton.enabled = isEnabled;
		}
		if (mc != null)
		{
			mc.enabled = isEnabled;
		}
		refreshHandCursor();
	}

	private function refreshHandCursor():Void
	{
		if (sprite != null)
		{
			sprite.buttonMode = isEnabled && useHandCursor;
		}
	}
	
	// Handlers

	private function interactiveObject_clickHandler(event:MouseEvent):Void
	{
		if (isEnabled)
		{
			// Dispatch
			clickSignal.dispatch(this);
		}
	}
}
