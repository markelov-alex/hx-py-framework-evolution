package v7.dresser;

import v7.lib.util.Signal.Signal2;
import v7.lib.util.Signal;

/**
 * IDresserController.
 * 
 */
interface IDresserController
{
	// State
	
	public var state(default, set):Array<Int>;

	// Signals

	public var stateChangeSignal(default, null):Signal<Array<Int>>;
	public var itemChangeSignal(default, null):Signal2<Int, Int>;

	// Methods
	
	public function load():Void;
	public function changeItem(itemIndex:Int, frame:Int):Void;
}
