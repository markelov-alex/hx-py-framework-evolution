package v0.dresser;

import v0.lib.ArrayUtil;
import v0.lib.Signal;

/**
 * DresserModel.
 * 
 */
class DresserModel
{
	// Settings

	// State
	
	public var state(default, set):Array<Int>;
	public function set_state(value:Array<Int>):Array<Int>
	{
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

	// Init

	public function new()
	{
	}

	// Methods

}
