package v5.dresser;

import v3.lib.net.transport.ITransport;
import v5.lib.net.parser.IParser;
import v5.lib.net.transport.BinarySocketTransport;
import v5.lib.net.transport.SocketTransport;
import v5.net.CustomBinaryParser;

/**
 * DresserProtocol.
 * 
 * Changes:
 *  - use new transport and parser.
 */
class DresserProtocol extends v3.dresser.DresserProtocol
{
	// Settings

	// State

	// todo move to Protocol
	override private function set_transport(value:ITransport):ITransport
	{
		var result = super.set_transport(value);
		if (result != null)
		{
			var transport:SocketTransport = Std.downcast(this.transport, SocketTransport);
			var parser:IParser = Std.downcast(this.parser, IParser);
			if (transport != null && parser != null)
			{
				transport.isBinary = parser.isBinary;
			}
		}
		return result;
	}

	// Signals

	// Init

	override private function init():Void
	{
		super.init();

		transportType = BinarySocketTransport;
		parserType = CustomBinaryParser;
	}

	// Methods
	
}
