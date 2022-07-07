package v3.lib.net.transport;

import openfl.events.DataEvent;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TimerEvent;
import openfl.net.XMLSocket;
import openfl.utils.Timer;
import v0.lib.IoC;
import v0.lib.Log;
import v0.lib.Signal;
import v3.lib.net.transport.ITransport;

/**
 * UTFSocketTransport.
 * 
 */
class UTFSocketTransport implements ITransport
{
	// Settings

	public var reconnectIntervalMs = 3000; // Set 0 to disable
	public var socketType = XMLSocket;

	// State

	public var host(default, null):String;
	public var port(default, null):Int;

	private var socket(default, set):XMLSocket;
	private function set_socket(value:XMLSocket):XMLSocket
	{
		var socket = this.socket;
		if (socket != value)
		{
			if (socket != null)
			{
				// Listeners
				socket.removeEventListener(Event.CONNECT, socket_connectHandler);
				socket.removeEventListener(Event.CLOSE, socket_closeHandler);
				socket.removeEventListener(DataEvent.DATA, socket_dataHandler);
				//socket.removeEventListener(ProgressEvent.PROGRESS, socket_progressHandler);
				socket.removeEventListener(ErrorEvent.ERROR, socket_errorHandler);
				socket.removeEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
				socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			}
			this.socket = socket = value;
			if (socket != null)
			{
				// Listeners
				socket.addEventListener(Event.CONNECT, socket_connectHandler);
				socket.addEventListener(Event.CLOSE, socket_closeHandler);
				socket.addEventListener(DataEvent.DATA, socket_dataHandler);
				//socket.addEventListener(ProgressEvent.PROGRESS, socket_progressHandler);
				socket.addEventListener(ErrorEvent.ERROR, socket_errorHandler);
				socket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
				socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			}
		}
		return socket;
	}

	public var isConnecting(default, null):Bool = false;
	public var isConnected(get, null):Bool;
	public function get_isConnected():Bool
	{
		return socket != null && socket.connected;
	}
	
	private var reconnectTimer = new Timer(0, 1);

	// Signals

	public var connectingSignal(default, null) = new Signal<ITransport>();
	public var connectedSignal(default, null) = new Signal<ITransport>();
	public var disconnectedSignal(default, null) = new Signal<ITransport>();
	public var closedSignal(default, null) = new Signal<ITransport>();
	public var reconnectSignal(default, null) = new Signal<ITransport>();
	public var receiveDataSignal(default, null) = new SignalDyn();
	public var errorSignal(default, null) = new SignalDyn();

	// Init

	public function new(?host:String, ?port:Int)
	{
		this.host = host;
		this.port = port;

		// Listeners
		reconnectTimer.addEventListener(TimerEvent.TIMER, reconnectTimer_timerSignalHandler);
	}

	public function dispose():Void
	{
		reconnectTimer.stop();
		if (socket != null)
		{
			socket.close();
		}
		socket = null;
	}

	private var _className:String;
	public function toString():String
	{
		if (_className == null)
		{
			_className = Type.getClassName(Type.getClass(this));
		}
		var status = isConnected ? "connected" : (isConnecting ? "connecting" : "disconnected");
		return '[$_className host:$host port:$port $status]';
	}

	// Methods

	public function connect(?host:String, ?port:Int):Void
	{
		if (socket == null)
		{
			socket = IoC.getInstance().create(socketType);
		}

		// Change address
		var isChanged = false;
		if (host != null)
		{
			isChanged = isChanged || this.host != host;
			this.host = host;
		}
		if (port != 0 && port != null)
		{
			isChanged = isChanged || this.host != host;
			this.port = port;
		}
		if ((isConnected || isConnecting) && !isChanged)
		{
			// Skip for same address
			return;
		}
		
		// Close previous
		close();

		// Connect
		if (this.host == null || this.port == 0)
		{
			Log.error('Trying to connect with not initialized host: ${this.host} or port: ${this.port} not set!');
			return;
		}
		isConnecting = true;
		socket.connect(this.host, this.port);
		// Dispatch
		connectingSignal.dispatch(this);
	}

	public function close():Void
	{
		isConnecting = false;
		reconnectTimer.stop();
		if (socket != null && socket.connected)
		{
			socket.close();
		}
	}

	private function reconnectLater():Void
	{
		if (isConnected || isConnecting || reconnectIntervalMs < 0)
		{
			// Disabled
			return;
		}
		if (reconnectIntervalMs == 0)
		{
			// Instant reconnect
			reconnectTimer_timerSignalHandler(null);
			return;
		}
		reconnectTimer.delay = reconnectIntervalMs;
		reconnectTimer.start();
	}

	public function send(plainData:Dynamic):Void
	{
		if (socket == null || !isConnected)
		{
			if (!isConnected)
			{
				connect();
			}
			Log.error('Cannot send $plainData because socket: $socket is not connected!');
			return;
		}
		socket.send(plainData);
	}

	// Handlers

	private function socket_connectHandler(event:Event):Void
	{
		isConnecting = false;
		// Dispatch
		connectedSignal.dispatch(this);
	}

	private function socket_closeHandler(event:Event):Void
	{
		// Dispatch
		disconnectedSignal.dispatch(this);
		closedSignal.dispatch(this);

		// Reconnect
		// (After signal dispatch to allow change address if no interval defined)
		reconnectLater();
	}

	private function socket_dataHandler(event:DataEvent):Void
	{
		Log.debug('>> Data received: ${event.data}');
		// Dispatch
		receiveDataSignal.dispatch(event.data);
	}

	private function socket_progressHandler(event:ProgressEvent):Void
	{
		Log.debug('Socket progress bytes: ${event.bytesLoaded} of ${event.bytesTotal}');
	}

	private function socket_errorHandler(event:ErrorEvent):Void
	{
		isConnecting = false;
		Log.error('Socket ERROR $event');
		// Dispatch
		errorSignal.dispatch(event);

		// Reconnect
		reconnectLater();
	}

	private function socket_ioErrorHandler(event:IOErrorEvent):Void
	{
		isConnecting = false;
		Log.error('Socket IO ERROR $event');
		// Dispatch
		errorSignal.dispatch(event);

		// Reconnect
		reconnectLater();
	}

	private function socket_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		isConnecting = false;
		Log.error('Socket SECURITY ERROR event: $event errorID: ${event.errorID}');
		// Dispatch
		errorSignal.dispatch(event);

		// Reconnect
		reconnectLater();
	}

	private function reconnectTimer_timerSignalHandler(event:TimerEvent):Void
	{
		reconnectTimer.stop();

		// (Host and port could be changed here)
		// Dispatch
		reconnectSignal.dispatch(this);

		// (Skip if connect() was called in a reconnectSignal handler)
		if (!isConnecting && !isConnected)
		{
			Log.debug('Reconnect');
			connect();
		}
	}
}
