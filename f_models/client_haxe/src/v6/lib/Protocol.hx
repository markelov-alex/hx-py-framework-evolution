package v6.lib;

import v0.lib.IoC;
import v0.lib.Log;

/**
 * Protocol.
 * 
 */
class Protocol
{
	// Settings

	public var url = "http://127.0.0.1:5000/storage/";

	// State

	private var parser:IParser;
	private var transport:ITransport;

	// Init

	public function new()
	{
		var ioc = IoC.getInstance();
		parser = ioc.create(IParser);
		transport = ioc.create(ITransport);
		transport.url = url;
		// Listeners
		transport.receiveDataSignal.add(transport_receiveDataSignalHandler);
	}

	// Methods

	public function send(data:Dynamic):Void
	{
		var plain:Dynamic = parser.serialize(data);
		Log.debug('<< Send: $data -> $plain');
		transport.send(plain, data);
	}
	
	// Override
	private function processData(data:Dynamic):Void
	{
	}
	
	// Handlers

	private function transport_receiveDataSignalHandler(plain:Dynamic):Void
	{
		var dataArray = parser.parse(plain);
		Log.debug(' >> Parsed: $dataArray');
		for (data in dataArray)
		{
			if (data != null && data.success)
			{
				processData(data);
			}
		}
	}
}
