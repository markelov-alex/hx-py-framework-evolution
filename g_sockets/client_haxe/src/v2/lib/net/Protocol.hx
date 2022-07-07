package v2.lib.net;

import haxe.Exception;
import haxe.Json;
import haxe.Timer;
import openfl.events.DataEvent;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.XMLSocket;
import v0.lib.IoC;
import v0.lib.Log;
import v0.lib.Signal;

/**
 * Protocol.
 * 
 * Base class for all protocol controllers.
 */
class Protocol implements IProtocol
{
	// Settings
	
	public var reconnectIntervalMs = 3000;

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
				socket.removeEventListener(ProgressEvent.PROGRESS, socket_progressHandler);
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
				socket.addEventListener(ProgressEvent.PROGRESS, socket_progressHandler);
				socket.addEventListener(ErrorEvent.ERROR, socket_errorHandler);
				socket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
				socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			}
		}
		return socket;
	}
	
	private var reconnectTimer:Timer;
	
	// Signals

	public var connectingSignal(default, null) = new Signal<IProtocol>();
	public var connectedSignal(default, null) = new Signal<IProtocol>();
	public var disconnectedSignal(default, null) = new Signal<IProtocol>();
	public var closedSignal(default, null) = new Signal<IProtocol>();
	public var reconnectSignal(default, null) = new Signal<IProtocol>();
	public var errorSignal(default, null) = new SignalDyn();

	// Init

	public function new(?host:String, ?port:Int)
	{
		this.host = host;
		this.port = port;
		
		socket = IoC.getInstance().getSingleton(XMLSocket);
	}

	/**
	 * Note: dispose() doesn't close the connection (because several protocols use 
	 * same connection, and disposing one of them would break down the others).
	 */
	public function dispose():Void
	{
		if (reconnectTimer != null)
		{
			reconnectTimer.stop();
			reconnectTimer = null;
		}
		socket = null;
	}

	// Methods

	public function connect(?host:String, ?port:Int):Void
	{
		var isChanged = false;
		if (host != null)
		{
			isChanged = isChanged || this.host != host;
			this.host = host;
		}
		if (port != 0)
		{
			isChanged = isChanged || this.host != host;
			this.port = port;
		}
		if (socket == null || socket.connected && !isChanged)
		{
			return;
		}
		
		// Close connection to another address
		close();
		
		// Connect
		if (this.host == null || this.port == 0)
		{
			Log.error('Trying to connect with host: ${this.host} or port: ${this.port} not set!');
		}
		Log.debug('Connecting to ${this.host}:${this.port}...');
		socket.connect(this.host, this.port);
	}

	public function close():Void
	{
		if (reconnectTimer != null)
		{
			reconnectTimer.stop();
			reconnectTimer = null;
		}
		if (socket != null && socket.connected)
		{
			socket.close();
		}
	}

	private function reconnectLater():Void
	{
		reconnectTimer = Timer.delay(function () {
			connect();

			if (reconnectTimer != null)
			{
				reconnectTimer.stop();//temp
				reconnectTimer = null;
			}
		}, reconnectIntervalMs);
	}

	private function send(data:Dynamic):Void
	{
		Log.debug('<< Send: $data');
		socket.send(Json.stringify(data));
	}

	private function processCommands(commands:Array<Dynamic>):Void
	{
	}

	// Handlers

	private function socket_connectHandler(event:Event):Void
	{
		Log.debug("CONNECTED");
	}

	private function socket_closeHandler(event:Event):Void
	{
		Log.debug('DISCONNECTED CLOSE');

		reconnectLater();
	}

	private function socket_dataHandler(event:DataEvent):Void
	{
		Log.debug('>> Data received: ${event.data}');
		try
		{
			var data = Json.parse(event.data);
			var commands:Array<Dynamic> = Std.isOfType(data, Array) ? data : [data];
			processCommands(commands);
		}
		catch (e:Exception)
		{
			Log.error(e);
		}
	}

	private function socket_progressHandler(event:ProgressEvent):Void
	{
		Log.info('Socket progress bytes: ${event.bytesLoaded} of ${event.bytesTotal}');
	}

	private function socket_errorHandler(event:ErrorEvent):Void
	{
		Log.error('Socket ERROR $event');
	}

	private function socket_ioErrorHandler(event:IOErrorEvent):Void
	{
		Log.error('Socket IO ERROR $event');
	}

	private function socket_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		Log.error('Socket SECURITY ERROR event: $event errorID: ${event.errorID}');

		// (Reconnect)
		reconnectLater();
	}
}
