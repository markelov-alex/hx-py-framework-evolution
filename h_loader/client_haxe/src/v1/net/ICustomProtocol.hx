package v1.net;

import v0.lib.util.Signal;

/**
 * ICustomProtocol.
 * 
 */
interface ICustomProtocol extends v0.net.ICustomProtocol
{
	// Signals

	public var gotoSignal(default, null):Signal<String>;
	
	// Methods

	public function goto(name:String):Void;
	
}
