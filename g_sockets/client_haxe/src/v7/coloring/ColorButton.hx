package v7.coloring;

import openfl.display.DisplayObject;
import openfl.geom.ColorTransform;
import v7.lib.components.RadioButton;

/**
 * ColorRadioButton.
 * 
 */
class ColorButton extends RadioButton
{
	// Settings
	
	public var fillPath = "fill";

	// State
	
	private var fill:DisplayObject;
	
	public var color(default, set):Int;
	public function set_color(value:Int):Int
	{
		if (color != value)
		{
			color = value;
			refreshColor();
		}
		return value;
	}

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
		fill = resolveSkinPath(fillPath);
		if (fill == null)
		{
			fill = skin;
		}
		
		// Apply
		refreshColor();
	}

	override private function unassignSkin():Void
	{
		fill = null;
		
		super.unassignSkin();
	}

	private function refreshColor():Void
	{
		if (fill != null)
		{
			var ct = new ColorTransform();
			ct.color = color;
			fill.transform.colorTransform = ct;
		}
	}
}
