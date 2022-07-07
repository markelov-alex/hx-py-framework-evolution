package v1.dresser;

import v0.lib.ArrayUtil;
import v0.lib.Log;
import v0.lib.Signal;

/**
 * DresserModel.
 * 
 */
class DresserModel
{
	// Settings

	// State
	
	public var state(default, set):Array<Int> = [];
	public function set_state(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(state, value))
		{
			state = value;
			// Dispatch
			stateChangeSignal.dispatch(value);
		}
		return value;
	}
	
	// Signals

	public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

	// Init

	public function new()
	{
		Log.info('$this v1');
	}

	// Methods

	public function changeItem(index:Int, value:Int):Void
	{
		if (state[index] != value)
		{
			state[index] = value;
			// Dispatch
			itemChangeSignal.dispatch(index, value);
		}
	}
}
