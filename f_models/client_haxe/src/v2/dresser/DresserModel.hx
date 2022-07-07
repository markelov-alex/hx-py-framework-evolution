package v2.dresser;

import openfl.net.SharedObject;
import v0.lib.Log;

/**
 * DresserModel.
 * 
 */
class DresserModel extends v1.dresser.DresserModel
{
	// Settings

	// State

	private var shared = SharedObject.getLocal("dresser");

	override public function set_state(value:Array<Int>):Array<Int>
	{
		shared.data.state = value;
		return super.set_state(value);
	}
	
	// Init

	public function new()
	{
		super();

		Log.info('$this v2');
		state = shared.data.state;
	}

	// Methods

//	override public function changeItem(index:Int, value:Int):Void
//	{
//		super.changeItem(index, value);
//		// No need as shared.data.state and state reference to the same object
//		shared.data.state = state;
//	}
}
