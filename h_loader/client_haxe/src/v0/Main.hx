package v0;

import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v0.coloring.ColoringController;
import v0.coloring.ColoringModel;
import v0.coloring.IColoringController;
import v0.coloring.IColoringModel;
import v0.dresser.DresserController;
import v0.dresser.IDresserController;
import v0.lib.AudioManager;
import v0.lib.components.Screens;
import v0.lib.IoC;
import v0.lib.LangManager;
import v0.lib.net.IProtocol;
import v0.lib.net.parser.IParser;
import v0.lib.net.transport.ITransport;
import v0.lib.net.transport.SocketTransport;
import v0.lib.util.Log;
import v0.menu.MenuScreen;
import v0.net.CustomProtocol;
import v0.net.ICustomProtocol;
import v0.net.parser.CustomMultiParser;

/**
 * Main.
 * 
 * Changes:
 *  - Screens.getInstance() -> ioc.getSingleton(Screens),
 *  - don't throw an exception if some text asset is absent.
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
		var screens = ioc.getSingleton(Screens);
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

		// (To enable client buffer for testing server buffer)
		var isPlus = event.keyCode == Keyboard.NUMPAD_ADD;
		if (isPlus || event.keyCode == Keyboard.NUMPAD_SUBTRACT)
		{
			var protocol:IProtocol = ioc.getSingleton(IProtocol);
			if (Reflect.hasField(protocol, "minPlainDataBufferLength"))
			{
				var val = Reflect.field(protocol, "minPlainDataBufferLength");
				val += isPlus ? 1 : -1;
				Reflect.setField(protocol, "minPlainDataBufferLength", val > 0 ? val : 0);
				Log.debug('Change minPlainDataBufferLength: $val');
			}
		}
	}
}
