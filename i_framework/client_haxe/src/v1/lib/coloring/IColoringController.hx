package v1.lib.coloring;

import v1.framework.util.Signal.Signal2;

/**
 * IColoringController.
 * 
 */
interface IColoringController
{
	// Signals

	public var applyColorSignal(default, null):Signal2<Int, Int>;

	// Methods

	public function load():Void;
	public function applyColor(itemIndex:Int, color:Int):Void;
}
