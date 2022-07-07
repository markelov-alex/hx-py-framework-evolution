package v7.dresser;

import v0.lib.Log;
import v6.lib.ITransport;
import v6.StorageProtocol;
import v7.lib.SocketTransport;

/**
 * DresserService.
 * 
 * Changes:
 *  - set URL for sockets.
 */
class DresserService extends StorageProtocol
{
	// Settings
	
	public var key = "dresser";

	// State

	// Init

	public function new()
	{
		super();
		Log.info('$this v6');

		transport.url = "127.0.0.1:5554";
		// Listeners
		cast(transport, SocketTransport).connectedSignal.add(transport_connectedSignalHandler);
		if (!cast(transport, SocketTransport).isConnected)
		{
			cast(transport, SocketTransport).connect();
		}
	}

	public function dispose():Void
	{
		if (transport != null)
		{
			// Listeners
			transport.receiveDataSignal.remove(transport_receiveDataSignalHandler);
			cast(transport, SocketTransport).connectedSignal.remove(transport_connectedSignalHandler);
			cast(transport, SocketTransport).dispose();
			transport = null;
		}
	}

	// Methods

	override public function send(data:Dynamic):Void
	{
		data.key = key;
		super.send(data);
	}

	override private function processData(data:Dynamic):Void
	{
		if (data.key == key)
		{
			super.processData(data);
		}
	}

	// For socket_server/v4
	public function goto():Void
	{
		send({command: "goto"});
	}

	override public function load():Void
	{
		goto(); // Temp, put here for simplicity
		super.load();
	}
	
	// Handlers

	private function transport_connectedSignalHandler(transport:ITransport):Void
	{
		load();
	}
}
