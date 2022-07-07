package v2.lib.net;

import haxe.Exception;
import openfl.utils.ByteArray.ByteArrayData;
import v0.lib.net.IProtocol;
import v0.lib.net.parser.IMultiParser;
import v0.lib.net.parser.IParser;
import v0.lib.net.transport.ITransport;
import v0.lib.util.Log;
import v0.lib.util.Signal;

/**
 * Protocol.
 * 
 * Base class for all protocol controllers.
 * 
 * Changes:
 *  - add ioc field,
 *  - create own transport and parser for a protocol,
 * todo add commandSignal for protocols from different modules that should use one connection.
 */
class Protocol extends Base implements IProtocol
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
	
	private var transport(default, set):ITransport;
	private function set_transport(value:ITransport):ITransport
	{
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
			transport = value;
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
		return value;
	}

	private var parser:IParser;

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
			Log.warn('To enable protocol versions, MultiParser should be used!');
			return null;
		}
		return multiParser.outputVersion;
	}
	public function set_version(value:String):String
	{
		if (multiParser == null)
		{
			Log.warn('Cannot set version: $value for protocol: $this! ' + 
				'To enable protocol versions, MultiParser should be used!');
			return null;
		}
		
		// Change version on server side (also changes multiParser.version)
		if (value != null && version != value)
		{
			if (isConnected)
			{
				// Switch to another version on the fly
				Log.debug(' (Add version: $value to pending: $pendingVersions)');
				pendingVersions.push(value);
				// Sets also multiParser.outputVersion = value
				send(value);
			}
			else
			{
				// Set on init or reset on disconnect
				multiParser.outputVersion = value;
				multiParser.inputVersion = value;
			}

			// Refresh isBinary
			transport.isOutputBinary = multiParser.isOutputBinary;
			transport.isInputBinary = multiParser.isInputBinary;
		}
		return multiParser.outputVersion;
	}
	
	private var pendingVersions:Array<String> = [];
	
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
		super();

		this.host = host;
		this.port = port;
	}

	// Override to change settings
	override private function init():Void
	{
		super.init();
		
		// One transport for one protocol
		//was transport = ioc.getSingleton(transportType);
		transport = ioc.create(transportType);
		// As MultiParser can be used, which has state, use own parser for each protocol
		//was parser = ioc.getSingleton(parserType);
		parser = ioc.create(parserType);
		// Initialize version
		version = defaultVersion;
	}

	/**
	 * Note: dispose() doesn't close the connection (because several protocols use 
	 * same connection, and disposing one of them would break down the others).
	 */
	override public function dispose():Void
	{
		connectingSignal.dispose();
		connectedSignal.dispose();
		disconnectedSignal.dispose();
		closedSignal.dispose();
		reconnectSignal.dispose();
		errorSignal.dispose();
		
		ioc = null;
		transport = null;
		parser = null;
		pendingVersions = [];
		queue = [];
		
		super.dispose();
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
		
		// List
		if (Std.isOfType(data, Array))
		{
			for (d in (data:Array<Dynamic>))
			{
				send(d);
			}
			return;
		}

		if (multiParser != null)
		{
			// Refresh isOutputBinary
			// (Version should be sent with old isOutputBinary value, 
			// that's why set before serialize())
			transport.isOutputBinary = multiParser.isOutputBinary;
		}
		// (If data is version, parser's isOutputBinary might change)
		var plain:Dynamic = parser.serialize(data);
		Log.debug('<< Send: $data -> $plain');
		transport.send(plain);
	}

	private function processCommand(command:Dynamic):Void
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

		send(version);
		
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
		// Reset version
		version = defaultVersion;
		
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
			if (multiParser != null && data[0] == multiParser.inputVersion)
			{
				// Version parsed
				var version:String = data[0];
				if (pendingVersions.contains(version))
				{
					// Receive the version that was send earlier by client
					// Needed to prevent infinite circling between client and server 
					// when 2 or more versions change each other on circle.
					Log.debug(' (Remove version: $version from pending: $pendingVersions)');
					pendingVersions.remove(version);
				}
				else
				{
					// Version changed by server (change also on client)
					if (this.version != version)
					{
						Log.debug(' (To be resent version: $version)');
						// (Use "send()" not "this.version=version" to do not add to pendingVersions)
						//this.version = version;
						send(version);
					}
				}

				// Refresh isInputBinary
				transport.isInputBinary = multiParser.isInputBinary;
				return;
			}
		}
		catch (e:Exception)
		{
			Log.error('Error while parsing data: $plainData! $e \n${e.details()}');
			#if debug
			throw e;
			#end
			return;
		}

		if (data == null || data.length == 0)
		{
			return;
		}

		//var commands:Array<Dynamic> = Std.isOfType(data, Array) ? data : [data];
		var commands = data;
		for (command in commands)
		{
			try
			{
				processCommand(command);
			}
			catch (e:Exception)
			{
				Log.error('Error while processing commands: $commands! $e \n${e.details()}');
				#if debug
				throw e;
				#end
			}
		}
	}
}
