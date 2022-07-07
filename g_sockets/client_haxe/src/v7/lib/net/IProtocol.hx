package v7.lib.net;

import v7.lib.util.Signal.SignalDyn;
import v7.lib.util.Signal;

/**
 * IProtocol.
 * 
 */
interface IProtocol
{
	// Settings
	
	public var isEnqueAndSendOnConnect:Bool;
	
	// State
	
	public var version(get, set):String;
	public var isConnecting(get, null):Bool;
	public var isConnected(get, null):Bool;

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
