package v1.lib.components;

import v1.lib.Signal;
import lime.text.UTF8String;
import openfl.events.MouseEvent;

/**
 * Button.
 * 
 * Changes:
 *  - replace TextField with Label,
 *  - move isEnabled to Component (for Resizer and future components),
 *  - sound -> soundClick.
 */
class Button extends Component
{
	// Settings
	
	public var captionPath = "caption";

	public var soundClick = "click_button";

	// State
	
	private var captionLabel:Label;
	
	public var data:Dynamic;
	
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
	
	public var caption(get, set):String;
	public function get_caption():String
	{
		return captionLabel.text;
	}
	public function set_caption(value:String):String
	{
		return captionLabel.text = value;
	}
	
	// Signals

	public var clickSignal(default, null) = new Signal<Button>();

	// Init

	public function new()
	{
		super();

		captionLabel = new Label();
		captionLabel.skinPath = captionPath;
		addChild(captionLabel);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
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

	override private function refreshEnabled():Void
	{
		super.refreshEnabled();
		
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
			AudioManager.playSound(soundClick);
			// Dispatch
			clickSignal.dispatch(this);
		}
	}
}
