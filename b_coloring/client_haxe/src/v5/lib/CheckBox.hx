package v5.lib;

import openfl.display.DisplayObject;

/**
 * CheckBox.
 * 
 */
class CheckBox extends Button
{
	// Settings
	
	public var checkedPath = "checked";
	public var uncheckedPath = "unchecked";

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
				checkedSignal.dispatch(this);
			}
			else
			{
				uncheckedSignal.dispatch(this);
			}
			toggleSignal.dispatch(this);
		}
		return value;
	}
	
	// Signal
	public var checkedSignal(default, null) = new Signal<CheckBox>();
	public var uncheckedSignal(default, null) = new Signal<CheckBox>();
	public var toggleSignal(default, null) = new Signal<CheckBox>();

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
		if (container != null)
		{
			checked = resolveSkinPath(checkedPath);
			unchecked = resolveSkinPath(uncheckedPath);
		}
		
		// Listeners
		clickSignal.add(clickSignalHandler);
		
		// Apply
		refreshChecked();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		clickSignal.remove(clickSignalHandler);

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

	private function clickSignalHandler(button:Button):Void
	{
		isChecked = !isChecked;
	}
}
