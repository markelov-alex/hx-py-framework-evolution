package v7.lib;

import haxe.Exception;
import openfl.events.DataEvent;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TimerEvent;
import openfl.net.XMLSocket;
import openfl.utils.Timer;
import v0.lib.IoC;
import v0.lib.Log;
import v0.lib.Signal;
import v6.lib.ITransport;

/**
 * SocketTransport.
 * 
 */
class SocketTransport implements ITransport
{
	// Settings
	
	public var url:String;
	public var reconnectIntervalMs = 3000; // Set 0 to disable

	// State
	
	private var socket:XMLSocket;
	private var reconnectTimer = new Timer(0, 1);
	
	public var isConnected(get, null):Bool;
	public function get_isConnected():Bool
	{
		return socket != null ? socket.connected : false;
	}

	// Signals
	
	public var connectedSignal(default, null) = new Signal<ITransport>();
	public var disconnectedSignal(default, null) = new Signal<ITransport>();
	public var receiveDataSignal(default, null) = new Signal<Dynamic>();
	public var errorSignal(default, null) = new Signal<Dynamic>();

	// Init

	public function new()
	{
		socket = IoC.getInstance().getSingleton(XMLSocket);
		// Listeners
		socket.addEventListener(Event.CONNECT, socket_connectHandler);
		socket.addEventListener(Event.CLOSE, socket_closeHandler);
		socket.addEventListener(DataEvent.DATA, socket_dataHandler);
		socket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
		socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
		
		// Listeners
		reconnectTimer.addEventListener(TimerEvent.TIMER, reconnectTimer_timerSignalHandler);
	}

	// Methods

	public function dispose():Void
	{
		if (socket != null)
		{
			// Listeners
			socket.removeEventListener(Event.CONNECT, socket_connectHandler);
			socket.removeEventListener(Event.CLOSE, socket_closeHandler);
			socket.removeEventListener(DataEvent.DATA, socket_dataHandler);
			socket.removeEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
			socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			socket = null;
		}
	}
	
	public function connect(?host:String, ?port:Int):Void
	{
		var urlParts = url != null ? url.split(":") : [];
		host = host != null ? host : urlParts[0];
		port = port != null ? port : Std.parseInt(urlParts[1]);
		close();
		Log.debug('Connecting to ${host}:${port}...');
		socket.connect(host, port);
	}
	
	public function close():Void
	{
		if (reconnectTimer != null)
		{
			reconnectTimer.stop();
			//reconnectTimer = null;
		}
		if (socket != null && socket.connected)
		{
			socket.close();
		}
	}
	
	private function reconnectLater():Void
	{
		if (reconnectIntervalMs < 0)
		{
			// Disabled
			Log.debug('Reconnection disabled. after: $reconnectIntervalMs');
			return;
		}
		Log.debug('Reconnect after: $reconnectIntervalMs');
		if (reconnectIntervalMs == 0)
		{
			// Instant reconnect
			reconnectTimer_timerSignalHandler(null);
			return;
		}
		reconnectTimer.delay = reconnectIntervalMs;
		reconnectTimer.start();
	}

	/**
	 * Note: data:Dynamic only needed to define method for RESTful server API. 
	 * Later we can refuse RESTful API in favor of command in plainData unifying 
	 * it with Sockets, so "method" and hence "data" paramater won't be needed 
	 * and will be removed.
	 */
	public function send(plainData:String, ?data:Dynamic):Void
	{
		if (socket.connected)
		{
			Log.debug('<< Send: $plainData');
			socket.send(plainData);
		}
	}
	
	// Handlers
	
	private function socket_connectHandler(event:Event):Void
	{
		Log.debug("CONNECTED");
		// Dispatch
		connectedSignal.dispatch(this);
	}

	private function socket_closeHandler(event:Event):Void
	{
		Log.debug("CLOSE");
		// Dispatch
		disconnectedSignal.dispatch(this);
		// Reconnect
		reconnectLater();
	}
	
	private function socket_dataHandler(event:DataEvent):Void
	{
		try
		{
			Log.debug('>> Receive: ${event.data}');
			// Dispatch
			receiveDataSignal.dispatch(event.data);
		}
		catch (e:Exception)
		{
			Log.error('$e data: ${event.data}');
			// Dispatch
			errorSignal.dispatch(e);
		}
	}

	private function socket_ioErrorHandler(event:IOErrorEvent):Void
	{
		Log.error('Socket IO ERROR $event');
		// Dispatch
		errorSignal.dispatch(event);
		disconnectedSignal.dispatch(this);
		// Reconnect
		reconnectLater();
	}

	private function socket_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		Log.error('Socket SECURITY ERROR event: $event errorID: ${event.errorID}');
		// Dispatch
		errorSignal.dispatch(event);
		disconnectedSignal.dispatch(this);
		// Reconnect
		reconnectLater();
	}
	
	private function reconnectTimer_timerSignalHandler(event:TimerEvent):Void
	{
		reconnectTimer.stop();

		Log.debug('Reconnect...');
		if (socket != null && !socket.connected)
		{
			Log.debug('Reconnect');
			connect();
		}
	}
}
