package v2.lib.components;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import v0.lib.util.Signal;

/**
 * CheckBox.
 * 
 */
class CheckBox extends Button
{
	// Settings
	
	public var checkedPath = "checked";
	public var uncheckedPath = "unchecked";

	// Not practically needed as 1 click could produce a dozen of sounds
	//public var soundChecked = "checkbox_checked";
	//public var soundUnchecked = "checkbox_unchecked";
	//public var soundToggle = "checkbox_toggle";
	public var soundCheckedClick = "click_checked";
	public var soundUncheckedClick = "click_unchecked";
	public var soundToggleClick = "click_toggle";

	// State
	
	private var checked:DisplayObject;
	private var unchecked:DisplayObject;
	
	public var isChecked(default, set):Bool = false;
	public function set_isChecked(value:Bool):Bool
	{
		if (isChecked != value)
		{
			isChecked = value;
			refreshChecked();
			// Dispatch
			if (value)
			{
				//audioManager.playSound(soundChecked);
				checkedSignal.dispatch(this);
			}
			else
			{
				//audioManager.playSound(soundUnchecked);
				uncheckedSignal.dispatch(this);
			}
			//audioManager.playSound(soundToggle);
			toggleSignal.dispatch(this);
		}
		return value;
	}
	
	// Signal
	public var checkedSignal(default, null) = new Signal<CheckBox>();
	public var uncheckedSignal(default, null) = new Signal<CheckBox>();
	public var toggleSignal(default, null) = new Signal<CheckBox>();

	// Init

	public function new()
	{
		super();

		soundClick = "click_checkbox";
	}

	override public function dispose():Void
	{
		checkedSignal.dispose();
		uncheckedSignal.dispose();
		toggleSignal.dispose();

		super.dispose();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Parse
		if (container != null)
		{
			checked = resolveSkinPath(checkedPath);
			unchecked = resolveSkinPath(uncheckedPath);
		}
		
		// Apply
		refreshChecked();
	}

	override private function unassignSkin():Void
	{
		checked = null;
		unchecked = null;
		
		super.unassignSkin();
	}

	private function refreshChecked():Void
	{
		if (checked != null)
		{
			checked.visible = isChecked;
		}
		if (unchecked != null)
		{
			unchecked.visible = !isChecked;
		}
	}
	
	// Handler

	override private function interactiveObject_clickHandler(event:MouseEvent):Void
	{
		var prevChecked = isChecked;
		isChecked = !isChecked;
		// Can be not changed for RadioButton (or if disabled)
		if (isChecked != prevChecked)
		{
			if (isChecked)
			{
				audioManager.playSound(soundCheckedClick);
			}
			else
			{
				audioManager.playSound(soundUncheckedClick);
			}
			audioManager.playSound(soundToggleClick);
		}
		
		// After isChecked changed (make unchecked SoundToggleButton sound)
		super.interactiveObject_clickHandler(event);
	}
}
