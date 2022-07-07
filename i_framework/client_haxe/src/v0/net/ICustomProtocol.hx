package v0.net;

import v0.lib.net.IProtocol;
import v0.lib.util.Signal;

/**
 * ICustomProtocol.
 * 
 */
interface ICustomProtocol extends IProtocol
{
	// Signals

	public var setDataSignal(default, null):Signal2<String, Dynamic>;
	public var updateDataSignal(default, null):Signal2<String, Dynamic>;
	public var gotoSignal(default, null):Signal<String>;
	
	// Methods

	public function load(name:String):Void;
	public function update(name:String, data:Dynamic):Void;
	public function goto(name:String):Void;
	
}
