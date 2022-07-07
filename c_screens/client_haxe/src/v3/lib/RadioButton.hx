package v3.lib;

/**
 * RadioButton.
 * 
 * Parent is used as radio button group. If you need to create another group, 
 * just create some empty component and add radio buttons there.
 */
class RadioButton extends CheckBox
{
	// Settings

	// State

	override public function set_isChecked(value:Bool):Bool
	{
		if (value && isChecked != value && parent != null)
		{
			// Uncheck other radio buttons in the group
			for (child in parent.children)
			{
				var radioButton = Std.downcast(child, RadioButton);
				if (radioButton != null && radioButton != this)
				{
					radioButton.isChecked = false;
				}
			}
		}
		return super.set_isChecked(value);
	}

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function clickSignalHandler(target:Button):Void
	{
		if (!isChecked)
		{
			isChecked = true;
		}
	}
}
