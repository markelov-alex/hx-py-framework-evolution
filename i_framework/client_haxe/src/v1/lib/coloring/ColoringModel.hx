package v1.lib.coloring;

import v1.lib.coloring.IColoringModel;
import v1.framework.util.ArrayUtil;
import v1.framework.util.Signal;

/**
 * ColoringModel.
 * 
 */
class ColoringModel implements IColoringModel
{
	// Settings
	
	public var defaultColor:Int = 0xF5DEB3;
	public var colors:Array<Int> = [
		0xEC7063, 0xAF7AC5, 0x85C1E9, 0x52BE80, 0x58D68D, 0xF4D03F, 0xF5B041, 0xCACFD2, 0xD7DBDD, 0x5D6D7E,
		0xCB4335, 0x6C3483, 0x1F618D, 0x1E8449, 0x239B56, 0xB8860B, 0xCA6F1E, 0x909497, 0x616A6B, 0x212F3D
	];
	public var maxPictureIndex = 0;

	// State
	
	/**
	 * To save and load the whole game state.
	 */
	@:isVar
	public var state(get, set):ColoringState;
	public function get_state():ColoringState
	{
		return {
			"pictureStates": pictureStates,
			"pictureIndex": pictureIndex,
			"colorIndex": colorIndex,
		};
	}
	public function set_state(value:ColoringState):ColoringState
	{
		if (state != value)
		{
			state = value;
			if (value != null)
			{
				// Set pictureStates first for pictureIndex setter to update currentPictureState
				pictureStates = value.pictureStates != null ? value.pictureStates : [];
				pictureIndex = value.pictureIndex;
				colorIndex = value.colorIndex;
			}
		}
		return value;
	}

	public var pictureStates(default, set):Array<Array<Int>> = [];
	public function set_pictureStates(value:Array<Array<Int>>):Array<Array<Int>>
	{
		if (value == null)
		{
			value = [];
		}
		pictureStates = value;
		// Refresh currentPictureState
		currentPictureState = pictureStates[pictureIndex];
		return pictureStates;
	}
	
	public var pictureIndex(default, set):Int = 0;
	public function set_pictureIndex(value:Int):Int
	{
		if (value >= maxPictureIndex)
		{
			value = maxPictureIndex - 1;
		}
		if (value < 0)
		{
			value = 0;
		}
		if (pictureIndex != value)
		{
			pictureIndex = value;

			// Refresh currentPictureState
			currentPictureState = pictureStates[value];
			
			// Dispatch
			pictureChangeSignal.dispatch(value);
		}
		return value;
	}
	
	public var currentPictureState(default, set):Array<Int>;
	public function set_currentPictureState(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(currentPictureState, value))
		{
			currentPictureState = value;
			
			// Refresh game state
			pictureStates[pictureIndex] = value;
			
			// Dispatch
			currentPictureStateChangeSignal.dispatch(value);
		}
		return value;
	}
	
	public var colorIndex(default, set):Int = -1;
	public function set_colorIndex(value:Int):Int
	{
		var colorIndex = this.colorIndex;
		if (colorIndex != value)
		{
			this.colorIndex = colorIndex = value;
			
			color = if (colorIndex < 0 || colorIndex >= colors.length)
				defaultColor else colors[colorIndex];
			
			// Dispatch
			colorChangeSignal.dispatch(value);
		}
		return value;
	}
	
	public var color(default, null):Int;

	// Signals

	public var pictureChangeSignal(default, null) = new Signal<Int>();
	public var currentPictureStateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var colorChangeSignal(default, null) = new Signal<Int>();
	
	// Init

	public function new()
	{
		colorIndex = 0;
	}

	// Methods

	public function dispose():Void
	{
		pictureChangeSignal.dispose();
		currentPictureStateChangeSignal.dispose();
		colorChangeSignal.dispose();
	}
	
}

typedef ColoringState = {
	var pictureStates:Array<Array<Int>>;
	var pictureIndex:Int;
	var colorIndex:Int;
}
