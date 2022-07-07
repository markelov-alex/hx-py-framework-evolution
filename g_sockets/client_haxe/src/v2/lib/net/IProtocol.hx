package v2.lib.net;

import v0.lib.Signal.SignalDyn;
import v0.lib.Signal;

/**
 * IProtocol.
 * 
 */
interface IProtocol
{
	// State

	// Signals

	public var connectingSignal(default, null):Signal<IProtocol>;
	public var connectedSignal(default, null):Signal<IProtocol>;
	public var disconnectedSignal(default, null):Signal<IProtocol>;
	public var closedSignal(default, null):Signal<IProtocol>;
	public var reconnectSignal(default, null):Signal<IProtocol>;
	public var errorSignal(default, null):SignalDyn;

	// Methods

	public function dispose():Void;
	public function connect(?host:String, ?port:Int):Void;
	public function close():Void;
}
