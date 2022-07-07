package v0.net;

import v0.lib.net.IProtocol;
import v0.lib.util.Signal.Signal2;

/**
 * ICustomProtocol.
 * 
 */
interface ICustomProtocol extends IProtocol
{
	// Settings

	// State

	// Signals

	public var setDataSignal(default, null):Signal2<String, Dynamic>;
	public var updateDataSignal(default, null):Signal2<String, Dynamic>;

	// Signals

	// Methods

	public function load(name:String):Void;
	public function update(name:String, data:Dynamic):Void;
}
