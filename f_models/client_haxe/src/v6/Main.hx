package v6;

import v0.lib.Log;
import v1.coloring.ColoringModel;
import v3.dresser.DresserModel;
import v6.lib.HTTPTransport;
import v6.lib.IParser;
import v6.lib.ITransport;
import v6.lib.JSONParser;

/**
 * Main.
 * 
 * Changes:
 *  - use commands -- unification of protocol for further using with sockets.
 * Note: dispose() to transport-protocol added to dispose SocketTransport in v7.
 */
class Main extends v5.Main
{
	override private function initialize():Void
	{
		super.initialize();
		Log.info('App version: v6');
		
		ioc.register(ITransport, HTTPTransport);
		ioc.register(IParser, JSONParser);

		ioc.register(DresserModel, v6.dresser.DresserModel);
		ioc.register(ColoringModel, v6.coloring.ColoringModel);
	}
}
