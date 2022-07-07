package v1.lib;

import lime.text.UTF8String;
import openfl.events.MouseEvent;
import openfl.text.TextField;

/**
 * Button.
 * 
 * Changes:
 *  - caption.
 */
class Button extends Component
{
	// Settings
	
	public var captionPath = "caption";

	// State
	
	private var captionText:TextField;
	
	public var data:Dynamic;
	
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
	
	public var caption(default, set):String;
	public function set_caption(value:String):String
	{
		if (caption != value)
		{
			caption = value;
			refreshCaption();
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
		
		// Parse
		captionText = Std.downcast(resolveSkinPath(captionPath), TextField);
		if (captionText != null)
		{
			captionText.mouseEnabled = false;
		}
		
		// Apply
		refreshEnabled();
		refreshCaption();
		
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

	private function refreshCaption():Void
	{
		if (captionText != null && caption != null)
		{
			captionText.text = new UTF8String(caption);
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
