package v6.coloring;

import v3.lib.net.transport.ITransport;
import v6.lib.net.transport.SocketTransport;
import v6.net.CustomMultiParser;

/**
 * ColoringProtocol.
 * 
 * Changes:
 *  - use new parser and transport.
 */
class ColoringProtocol extends v3.coloring.ColoringProtocol
{
	// Settings

	// State
	
	// Init

	override private function init():Void
	{
		super.init();

		transportType = SocketTransport;
		parserType = CustomMultiParser;
	}

	// Methods

	// todo move to Protocol.version setter in v7
	public function changeVersion(version:String):Void
	{
		send(version);
		
		// No need for AutoMultiParser
//		if (Reflect.hasField("version"))
//		{
//			parser.version = version;
//		}
		
		refreshTransportByParser();
	}

	private function refreshTransportByParser():Void
	{
		//temp
		if (Reflect.hasField(transport, "isBinary") && Reflect.hasField(parser, "isBinary"))
		{
			Reflect.setProperty(transport, "isBinary", Reflect.getProperty(parser, "isBinary"));
		}
		// (use line below in next versions)
		//transport.isBinary = parser.isBinary;
	}
	
	// Handlers
	
	override private function transport_connectedSignalHandler(target:ITransport):Void
	{
		// Reset version on reconnect
		Reflect.setProperty(parser, "version", Reflect.getProperty(parser, "defaultVersion"));
		refreshTransportByParser();
		
		super.transport_connectedSignalHandler(target);
	}

	override private function transport_receiveDataSignalHandler(plainData:Dynamic):Void
	{
		super.transport_receiveDataSignalHandler(plainData);
		// If parser.version changed by data from server, transport should be also updated
		refreshTransportByParser();
	}
}
