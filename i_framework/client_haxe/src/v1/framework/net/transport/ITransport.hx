package v1.framework.net.transport;

import v1.framework.util.Signal.SignalDyn;
import v1.framework.util.Signal;

/**
 * ITransport.
 * 
 * Socket, XMLSocket or even Request (for protocol over HTTP) 
 * can be used as actual transport.
 */
interface ITransport
{
	// Settings

	public var reconnectIntervalMs:Int;
	public var isOutputBinary:Bool;
	public var isInputBinary:Bool;
	
	// State

	public var host(default, null):String;
	public var port(default, null):Int;
	public var isConnecting(default, null):Bool;
	public var isConnected(get, null):Bool;
	
	// Signals

	public var connectingSignal(default, null):Signal<ITransport>;
	public var connectedSignal(default, null):Signal<ITransport>;
	public var disconnectedSignal(default, null):Signal<ITransport>;
	public var closedSignal(default, null):Signal<ITransport>;
	public var reconnectSignal(default, null):Signal<ITransport>;
	public var receiveDataSignal(default, null):SignalDyn;
	public var errorSignal(default, null):SignalDyn;

	// Methods
	
	public function connect(?host:String, ?port:Int):Void;
	public function close():Void;
	
	/**
	 * plainData: string or bytes.
	 */
	public function send(plainData:Dynamic):Void;

}
