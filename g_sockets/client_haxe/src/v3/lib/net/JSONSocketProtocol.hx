package v3.lib.net;

import v3.lib.net.parser.JSONParser;
import v3.lib.net.transport.UTFSocketTransport;

/**
 * JSONSocketProtocol.
 * 
 */
class JSONSocketProtocol extends Protocol
{
	// Settings

	// State

	// Init

	override private function init():Void
	{
		super.init();
		
		transportType = UTFSocketTransport;
		parserType = JSONParser;
	}

	// Methods

}
