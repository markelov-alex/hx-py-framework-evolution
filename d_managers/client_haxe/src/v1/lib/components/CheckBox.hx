package v1.lib.components;

import openfl.display.DisplayObject;
import openfl.events.MouseEvent;
import v1.lib.Signal;

/**
 * CheckBox.
 * 
 * Changes:
 *  - clickSignal -> override interactiveObject_clickHandler(),
 *  - use soundChecked, soundUnchecked, soundToggle,
 *  - checkChangeSignal -> toggleSignal.
 */
class CheckBox extends Button
{
	// Settings
	
	public var checkedPath = "checked";
	public var uncheckedPath = "unchecked";

	public var soundChecked = "click_checked";
	public var soundUnchecked = "click_unchecked";
	public var soundToggle = "click_toggle";

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
				AudioManager.playSound(soundChecked);
				checkedSignal.dispatch(this);
			}
			else
			{
				AudioManager.playSound(soundUnchecked);
				uncheckedSignal.dispatch(this);
			}
			AudioManager.playSound(soundToggle);
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
		isChecked = !isChecked;
		// After isChecked changed (make unchecked SoundToggleButton sound)
		super.interactiveObject_clickHandler(event);
	}
}
