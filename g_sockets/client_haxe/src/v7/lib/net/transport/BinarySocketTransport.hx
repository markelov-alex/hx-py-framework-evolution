package v7.lib.net.transport;

import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.events.TimerEvent;
import openfl.net.Socket;
import openfl.utils.ByteArray;
import openfl.utils.Timer;
import v7.lib.IoC;
import v7.lib.net.transport.ITransport;
import v7.lib.util.BytesUtil;
import v7.lib.util.Log;
import v7.lib.util.Signal;

/**
 * BinarySocketTransport.
 * 
 */
class BinarySocketTransport implements ITransport
{
	// Settings

	public var reconnectIntervalMs = 3000; // Set 0 to disable
	public var socketType = Socket;
	public var isBinary = true;

	// State

	public var host(default, null):String;
	public var port(default, null):Int;

	private var socket(default, set):Socket;
	private function set_socket(value:Socket):Socket
	{
		var socket = this.socket;
		if (socket != value)
		{
			if (socket != null)
			{
				// Listeners
				socket.removeEventListener(Event.CONNECT, socket_connectHandler);
				socket.removeEventListener(Event.CLOSE, socket_closeHandler);
				socket.removeEventListener(ProgressEvent.SOCKET_DATA, socket_socketDataHandler);
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
				socket.addEventListener(ProgressEvent.SOCKET_DATA, socket_socketDataHandler);
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

	#if !js
	// Buffer for parsing (cannot use socket as its buffer is for receiving data)
	@:noCompletion private var inputBuffer:ByteArray = new ByteArray();
	// Buffer for dispatching received data
	@:noCompletion private var inputBuffer2:ByteArray = new ByteArray();
	#end

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
		if (isConnected && !isChanged)
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
		inputBuffer.clear();
		isConnecting = false;
		reconnectTimer.stop();
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
		if (socket == null || !socket.connected)
		{
			Log.error('Cannot send $plainData because socket: $socket is not connected!');
			return;
		}
		if (!Std.isOfType(plainData, ByteArrayData))
		{
			Log.error('$this accepts only ByteArray as data! data: $plainData');
			return;
		}
		var isTesting = true;
		if (isTesting)
		{
			// Send in several messages for testing server
			var middle = Math.ceil(plainData.length / 2);
			Log.debug('(Send bytes: ${BytesUtil.toHex(plainData, 0, middle)})');
			socket.writeBytes(plainData, 0, middle);
			socket.flush();
			Log.debug('(Send bytes: ${BytesUtil.toHex(plainData, middle)})');
			socket.writeBytes(plainData, middle);
			socket.flush();
		}
		else
		{
			Log.debug('Send bytes: ${BytesUtil.toHex(plainData)}');
			socket.writeBytes(plainData);
			socket.flush();
		}
	}
	
	// Utility

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

	private function socket_socketDataHandler(event:ProgressEvent):Void
	{
//		#if !js
		if (inputBuffer.length > 0)
		{
			Log.debug('(Prev buffer: ${BytesUtil.toHex(inputBuffer)} position: ${inputBuffer.position})');
		}
		// Copy to buffer
		socket.readBytes(inputBuffer, inputBuffer.length, socket.bytesAvailable);
		
		// Output
		inputBuffer.endian = socket.endian;
		inputBuffer.position = 0;
		
		Log.debug('>> Received: ${BytesUtil.toHex(inputBuffer)}');
		// Dispatch
		receiveDataSignal.dispatch(inputBuffer);
		
		// Clear
		if (inputBuffer.position == inputBuffer.length)
		{
			// Whole buffer was parsed and processed
			inputBuffer.clear();
		}
		else
		{
			// Some data left unparsed 
			// (Clear parsed data (before current position) 
			// and leave unparsed data (after position) in buffer)
			inputBuffer2.clear();
			Log.debug(' Parsed data to be cleared: ${BytesUtil.toHex(inputBuffer, 0, inputBuffer.position)}');
			inputBuffer2.writeBytes(inputBuffer, inputBuffer.position);
			var temp = inputBuffer2;
			inputBuffer2 = inputBuffer;
			inputBuffer = temp;
			Log.debug(' Unparsed data: ${BytesUtil.toHex(inputBuffer)}');
		}
//		#else
//		//???
//		// Dispatch
//		receiveDataSignal.dispatch(socket.readBytes(socket.bytesAvailable));
//		#end
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
