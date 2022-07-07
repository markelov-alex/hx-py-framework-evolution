package v2.coloring;

import v0.lib.Signal.Signal2;

/**
 * IColoringProtocol.
 * 
 */
interface IColoringProtocol
{
	// Signals

	public var applyColorSignal(default, null):Signal2<Int, Int>;

	// Methods

	public function load():Void;
	public function applyColor(itemIndex:Int, color:Int):Void;
}
