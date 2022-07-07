package v1.coloring;

import v0.lib.ArrayUtil;
import v0.lib.Log;
import v0.lib.Signal;

/**
 * ColoringModel.
 * 
 */
class ColoringModel
{
	// Settings
	
	public var defaultColor:Int = -1;
	public var colors:Array<Int>;
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
		pictureStates = value;
		// Refresh currentPictureState
		currentPictureState = pictureStates[pictureIndex];
		return value;
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
	
	public var colorIndex(default, set):Int = 0;
	public function set_colorIndex(value:Int):Int
	{
		if (colorIndex != value)
		{
			colorIndex = value;
			
			// Dispatch
			colorChangeSignal.dispatch(value);
		}
		return value;
	}

	// Signals

	public var pictureChangeSignal(default, null) = new Signal<Int>();
	public var currentPictureStateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var colorChangeSignal(default, null) = new Signal<Int>();

	// Init

	public function new()
	{
		Log.info('$this v1');
	}

	// Methods

}

typedef ColoringState = {
	var pictureStates:Array<Array<Int>>;
	var pictureIndex:Int;
	var colorIndex:Int;
}
