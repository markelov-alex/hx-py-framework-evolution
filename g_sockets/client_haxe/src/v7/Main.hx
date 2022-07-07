package v7;

import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v7.coloring.ColoringController;
import v7.coloring.ColoringModel;
import v7.coloring.IColoringController;
import v7.coloring.IColoringModel;
import v7.dresser.DresserController;
import v7.dresser.IDresserController;
import v7.lib.AudioManager;
import v7.lib.components.Screens;
import v7.lib.IoC;
import v7.lib.LangManager;
import v7.lib.net.IProtocol;
import v7.lib.net.parser.IParser;
import v7.lib.net.transport.ITransport;
import v7.lib.net.transport.SocketTransport;
import v7.lib.util.Log;
import v7.menu.MenuScreen;
import v7.net.CustomProtocol;
import v7.net.ICustomProtocol;
import v7.net.parser.CustomMultiParser;

/**
 * Main.
 * 
 * Changes:
 *  - almost final version of game with sockets,
 *  - use protocols as controllers,
 *  - use only one protocol to do not parse same data twice (previously, 
 *    we had one transport and two protocols with one parser each),
 *  - todo change actual protocol version only after confirmed from the other side - 
 *  	todo make two parsers inside MultiParser: one for parsing and one for serialization.
 */
class Main extends Sprite
{
	// Settings

	private var host = "localhost";
	private var port = 5555;
	
	// State
	
	private var ioc:IoC;
	private var protocol:IProtocol;
	private var versions:Array<String>;

	// Init

	public function new()
	{
		super();

		init();
	}
	
	private function init():Void
	{
		ioc = IoC.getInstance();
		
		// First of all set up IoC (register all class substitution, change defaultAssetName)
		configureApp();

		// Initialize managers
		ioc.load();
		LangManager.getInstance().load();
		AudioManager.getInstance().load();

		// Start up the app (view)
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);

		// Connect (logic)
		protocol = ioc.getSingleton(IProtocol);
		protocol.connect(host, port);

		// For switching protocol version
		// (Get versions)
		var parser = new CustomMultiParser();
		versions = parser.versions;
		// Listeners
		stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
	}
	
	private function configureApp():Void
	{
		// Note: Using interfaces we can substitute some class without extending it, 
		// but only implementing the same interface.
		ioc.register(IDresserController, DresserController);
		ioc.register(IColoringModel, ColoringModel);
		ioc.register(IColoringController, ColoringController);
		ioc.register(IProtocol, CustomProtocol);
		ioc.register(ICustomProtocol, CustomProtocol);
		ioc.register(ITransport, SocketTransport);
		ioc.register(IParser, CustomMultiParser);
	}
	
	// Handlers

	private function stage_keyUpHandler(event:KeyboardEvent):Void
	{
		if (event.keyCode >= Keyboard.NUMBER_1 && event.keyCode <= Keyboard.NUMBER_9)
		{
			var index = event.keyCode - Keyboard.NUMBER_1;
			var version = versions[index];
			trace('');
			Log.debug('SET all VERSIONS: $versions');
			for (v in versions)
			{
				// Send multiple version messages at once
				protocol.version = v;
			}
			trace('');
			Log.debug('SET next VERSION: $version');
			protocol.version = version;
			Log.debug('(END SET next VERSION: $version)');
			trace('');
		}
	}
}
