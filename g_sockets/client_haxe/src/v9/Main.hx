package v9;

import v7.lib.net.IProtocol;
import v7.lib.net.parser.IParser;
import v7.net.ICustomProtocol;
import v9.net.CustomProtocol2;
import v9.net.parser.CustomMultiParser;

/**
 * Main.
 * 
 * Press Numpad_minus to disable requests buffering. 
 * 
 * Changes:
 *  - fix bug demonstrated in v8 by using different parsers for serialize() and 
 *  parse() methods.
 */
class Main extends v8.Main
{
	// Settings

	
	// State
	
	// Init
	
	override private function configureApp():Void
	{
		super.configureApp();
		ioc.register(IParser, CustomMultiParser);
		ioc.register(IProtocol, CustomProtocol2);
		ioc.register(ICustomProtocol, CustomProtocol2);
	}
}
