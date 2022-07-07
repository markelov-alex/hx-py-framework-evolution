package v0.lib.components;

import openfl.events.MouseEvent;
import v0.lib.util.Signal;

/**
 * Button.
 * 
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

	override private function init():Void
	{
		super.init();
		
		captionLabel = createComponent(Label);
		captionLabel.skinPath = captionPath;
		addChild(captionLabel);
	}

	override public function dispose():Void
	{
		clickSignal.dispose();

		super.dispose();
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
			audioManager.playSound(soundClick);
			// Dispatch
			clickSignal.dispatch(this);
		}
	}
}
