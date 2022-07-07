package v7;

import v0.coloring.Coloring;
import v0.dresser.Dresser;
import v0.lib.Log;
import v1.coloring.ColoringModel;
import v3.dresser.DresserModel;
import v6.lib.ITransport;
import v7.lib.SocketTransport;

/**
 * Main.
 * 
 * Changes:
 *  - use sockets instead of HTTP (with same StorageProtocol and other classes).
 */
class Main extends v6.Main
{
	override private function initialize():Void
	{
		super.initialize();
		Log.info('App version: v7');

		ioc.register(ITransport, SocketTransport);
//		ioc.register(IParser, JSONParser);

		// (Socket URL set, service.dispose() added)
		ioc.register(DresserModel, v7.dresser.DresserModel);
		ioc.register(ColoringModel, v7.coloring.ColoringModel);
		// (model.dispose() added)
		ioc.register(Dresser, v7.dresser.Dresser);
		ioc.register(Coloring, v7.coloring.Coloring);
	}
}
