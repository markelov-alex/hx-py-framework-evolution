package v7.lib.net;

import haxe.Exception;
import openfl.utils.ByteArray.ByteArrayData;
import v7.lib.IoC;
import v7.lib.net.parser.IMultiParser;
import v7.lib.net.parser.IParser;
import v7.lib.net.transport.ITransport;
import v7.lib.util.Log;
import v7.lib.util.Signal;

/**
 * Protocol.
 * 
 * Base class for all protocol controllers.
 */
class Protocol implements IProtocol
{
	// Settings
	
	public var isEnqueAndSendOnConnect = false;
	// (Class or id string)
	public var transportType:Dynamic = ITransport;
	public var parserType:Dynamic = IParser;
	public var defaultVersion:String;

	// State

	private var host:String;
	private var port:Int;
	
	private var _transport:ITransport;
	@:isVar
	private var transport(get, set):ITransport;
	public function get_transport():ITransport
	{
		// (Don't create in constructor to enable set up types. 
		// Also connect() can be called from another protocol class, 
		// so it's also not a place.)
		if (_transport == null)
		{
			transport = IoC.getInstance().getSingleton(transportType);
		}
		return _transport;
	}
	private function set_transport(value:ITransport):ITransport
	{
		var transport = this._transport;
		if (transport != value)
		{
			if (transport != null)
			{
				isConnecting = false;
				// Listeners
				transport.connectingSignal.remove(transport_connectingSignalHandler);
				transport.connectedSignal.remove(transport_connectedSignalHandler);
				transport.disconnectedSignal.remove(transport_disconnectedSignalHandler);
				transport.closedSignal.remove(transport_closedSignalHandler);
				transport.reconnectSignal.remove(transport_reconnectSignalHandler);
				transport.receiveDataSignal.remove(transport_receiveDataSignalHandler);
				transport.errorSignal.remove(transport_errorSignalHandler);
			}
			this._transport = transport = value;
			if (transport != null)
			{
				// Listeners
				transport.connectingSignal.add(transport_connectingSignalHandler);
				transport.connectedSignal.add(transport_connectedSignalHandler);
				transport.disconnectedSignal.add(transport_disconnectedSignalHandler);
				transport.closedSignal.add(transport_closedSignalHandler);
				transport.reconnectSignal.add(transport_reconnectSignalHandler);
				transport.receiveDataSignal.add(transport_receiveDataSignalHandler);
				transport.errorSignal.add(transport_errorSignalHandler);
			}
		}
		return transport;
	}

	private var parser(get, null):IParser;
	private function get_parser():IParser
	{
		if (parser == null)
		{
			parser = IoC.getInstance().getSingleton(parserType);
		}
		return parser;
	}

	private var multiParser(get, null):IMultiParser;
	private function get_multiParser():IMultiParser
	{
		return Std.downcast(parser, IMultiParser);
	}
	
	@:isVar
	public var version(get, set):String;
	public function get_version():String
	{
		if (multiParser == null)
		{
			Log.warn('To enable protocol versions MultiParser should be used!');
			return null;
		}
		return multiParser.version;
	}
	public function set_version(value:String):String
	{
		if (multiParser == null)
		{
			Log.warn('Cannot set version: $value for protocol: $this!' + 
				' To enable protocol versions MultiParser should be used!');
			return null;
		}
		
		// Change version on server side (also changes multiParser.version)
		if (isConnected && value != null && version != value)
		{
			send(value);
		}
		
		// Set ("=value" is not necessary as already set with "send(value)")
		var version = multiParser.version = value;
		// Refresh isBinary
		transport.isBinary = parser.isBinary;
		return version;
	}
	
	public var isConnecting(get, null):Bool;
	public function get_isConnecting():Bool
	{
		return transport != null && transport.isConnecting;
	}
	public var isConnected(get, null):Bool;
	public function get_isConnected():Bool
	{
		return transport != null && transport.isConnected;
	}
	
	private var queue:Array<Dynamic> = [];
	
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
		init();
	}

	// Override to change settings
	private function init():Void
	{
	}

	/**
	 * Note: dispose() doesn't close the connection (because several protocols use 
	 * same connection, and disposing one of them would break down the others).
	 */
	public function dispose():Void
	{
		transport = null;
	}

	private var _className:String;
	public function toString():String
	{
		if (_className == null)
		{
			_className = Type.getClassName(Type.getClass(this));
		}
		var host = transport != null ? transport.host : this.host;
		var port = transport != null ? transport.port : this.port;
		var status = isConnected ? "connected" : (isConnecting ? "connecting" : "disconnected");
		return '[$_className host:$host port:$port $status]';
	}

	// Methods

	/**
	 * Start.
	 */
	public function connect(?host:String, ?port:Int):Void
	{
		if (host != null)
		{
			this.host = host;
		}
		if (port != null)
		{
			this.port = port;
		}
		
		// Connect
		transport.connect(this.host, this.port);
	}

	/**
	 * Stop.
	 */
	public function close():Void
	{
		if (transport != null)
		{
			transport.close();
		}
	}

	private function send(data:Dynamic):Void
	{
		if (!transport.isConnected)
		{
			if (isEnqueAndSendOnConnect)
			{
				Log.debug('No connection, enqueue: $data');
				queue.push(data);
			}
			else
			{
				Log.error('Cannot send: $data as transport is not connected!');
			}
			connect();
			return;
		}
		
		var plain:Dynamic = parser.serialize(data);
		Log.debug('<< Send: $data -> $plain');
		transport.send(plain);
	}

	private function processCommands(commands:Array<Dynamic>):Void
	{
	}

	// Handlers

	private function transport_connectingSignalHandler(target:ITransport):Void
	{
		Log.debug('Connecting to $host:$port...');
		// Redispatch
		connectingSignal.dispatch(this);
	}

	private function transport_connectedSignalHandler(target:ITransport):Void
	{
		Log.debug('CONNECTED to $host:$port');

		// Initiate/reset protocol version. Place here to:
		// 1. Send version to server with the very first message.
		// 2. Reset version on reconnect.
		// Besides, as version affects only parser and parser only used when 
		// transport is connected, there is no needed to reset version in any 
		// other place (in constructor or disconnect handler).
		version = defaultVersion;
		
		if (queue.length > 0)
		{
			Log.debug('Send ${queue.length} enqueued messages');
			for (data in queue)
			{
				send(data);
			}
		}

		// Redispatch
		connectedSignal.dispatch(this);
	}

	private function transport_disconnectedSignalHandler(target:ITransport):Void
	{
		Log.debug('DISCONNECTED');
		
		// Redispatch
		disconnectedSignal.dispatch(this);
	}

	private function transport_closedSignalHandler(target:ITransport):Void
	{
		Log.debug('CLOSED');
		
		// Redispatch
		closedSignal.dispatch(this);
	}

	private function transport_reconnectSignalHandler(target:ITransport):Void
	{
		// Redispatch
		reconnectSignal.dispatch(this);
	}

	private function transport_errorSignalHandler(error:Dynamic):Void
	{
		//todo ErrorInfo
		// Redispatch
		errorSignal.dispatch(error);
	}

	private function transport_receiveDataSignalHandler(plainData:Dynamic):Void
	{
		var data:Array<Dynamic>;
		try
		{
			// If there is more than 1 protocol for a transport, bytes might 
			// come with position at the end as it have been already parsed 
			// by previous parser. So, reset position.
			if (Std.isOfType(plainData, ByteArrayData))
			{
				(plainData:ByteArrayData).position = 0;
			}
			data = parser.parse(plainData);
			// (After parser.parse() because it can change parser.isBinary by parsing version 
			// message, which could change parser for MultiParser used. Before processCommands(), 
			// because it can throw exception and transport's isBinary won't be changed.)
			transport.isBinary = parser.isBinary;
		}
		catch (e:Exception)
		{
			Log.error('Error while parsing data: $plainData! $e \n${e.details()}');
			return;
		}

		if (data == null || data.length == 0)
		{
			return;
		}

		//var commands:Array<Dynamic> = Std.isOfType(data, Array) ? data : [data];
		var commands = data;
		Log.debug('Parsed commands to be processed: $commands');
		try
		{
			processCommands(commands);
		}
		catch (e:Exception)
		{
			Log.error('Error while processing commands: $commands! $e \n${e.details()}');
		}
	}
}
