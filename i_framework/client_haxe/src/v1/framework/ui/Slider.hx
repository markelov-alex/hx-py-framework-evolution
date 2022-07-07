package v1.framework.ui;

import v1.framework.ui.controls.Drag;
import openfl.events.MouseEvent;
import v1.framework.ui.Component;
import v1.framework.util.Signal;

/**
 * Slider.
 * 
 */
class Slider extends Component
{
	// Settings
	
	public var thumbPath = "thumb";
	public var trackPath = "track";

	public var minValueStep:Float = 0.01;
	public var wheelRatioStep:Float = 0.05;

	/**
	 * If minValue > maxValue, then increasing the value we decreasing the ratio.
	 */
	public var minValue(default, set):Float = 0;
	public function set_minValue(value:Float):Float
	{
		if (minValue != value)
		{
			minValue = value;

			// As ratio stay same, value should change
			// Dispatch
			changeSignal.dispatch(this);
		}
		return value;
	}

	public var maxValue(default, set):Float = 100;
	public function set_maxValue(value:Float):Float
	{
		if (maxValue != value)
		{
			maxValue = value;

			// As ratio stay same, value should change
			// Dispatch
			changeSignal.dispatch(this);
		}
		return value;
	}
	
	// State
	
	@:isVar
	public var ratio(get, set):Float;
	public function get_ratio():Float
	{
		return drag != null ? drag.ratioMain : -1;
	}
	public function set_ratio(val:Float):Float
	{
		return drag != null ? (drag.ratioMain = val) : -1;
	}

	public var value(get, set):Float;
	public function get_value():Float
	{
		var value = ratio * (maxValue - minValue) + minValue;
		return minValueStep > 0 ? value - value % minValueStep : value;
	}
	public function set_value(value:Float):Float
	{
		if (minValue == maxValue)
		{
			return ratio = 0;
		}
		value = value < minValue ? minValue : (value > maxValue ? maxValue : value);
		ratio = (value - minValue) / (maxValue - minValue);
		return value;
	}

	public function changeValueBy(valueDiff:Float):Void
	{
		var valueSize = maxValue - minValue;
		var ratioDiff = if (valueSize != 0) valueDiff / valueSize else 0;
		ratio += ratioDiff;
	}
	
	private var drag:Drag;
	
	// Signals

	public var changeSignal(default, null) = new Signal<Slider>();

	// Init

	override private function init():Void
	{
		super.init();
		
		drag = createComponent(Drag);
		drag.useHandCursor = true;
		drag.skinPath = thumbPath;
		drag.trackPath = trackPath != null && trackPath != "" ? "parent." + trackPath : trackPath;
		// Listeners
		drag.changeSignal.add(drag_changeSignalHandler);
		addChild(drag);
	}

	override public function dispose():Void
	{
		changeSignal.dispose();
		
		super.dispose();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Listeners
		skin.addEventListener(MouseEvent.MOUSE_WHEEL, skin_mouseWheelHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(MouseEvent.MOUSE_WHEEL, skin_mouseWheelHandler);
		
		super.unassignSkin();
	}
	
	// Handlers

	private function drag_changeSignalHandler(target:Drag):Void
	{
		// Dispatch
		changeSignal.dispatch(this);
	}

	private function skin_mouseWheelHandler(event:MouseEvent):Void
	{
		ratio += wheelRatioStep * event.delta;
	}
}
