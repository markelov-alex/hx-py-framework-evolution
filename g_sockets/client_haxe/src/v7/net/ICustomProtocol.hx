package v7.net;

import v7.lib.net.IProtocol;
import v7.lib.util.Signal.Signal2;

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
