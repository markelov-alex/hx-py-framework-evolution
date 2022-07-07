package v0;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v0.coloring.IColoringController;
import v0.coloring.IColoringModel;
import v0.dresser.IDresserController;
import v0.lib.net.IProtocol;
import v0.lib.net.parser.IParser;
import v0.lib.net.transport.ITransport;
import v0.lib.util.Log;
import v0.net.ICustomProtocol as ICustomProtocol0;
import v0.net.ICustomProtocol;
import v0.net.parser.CustomMultiParser;
import v0.coloring.ColoringController;
import v0.coloring.ColoringModel;
import v0.dresser.DresserController;
import v0.lib.components.KeyControl;
import v0.lib.GameApplication;
import v0.lib.net.transport.SocketTransport;
import v0.menu.MenuScreen;
import v0.net.CustomProtocol;

/**
 * AppMain.
 * 
 */
class AppMain extends GameApplication
{
	// Settings
	
	// State
	
	private var keyControl:KeyControl;
	private var versions:Array<String>;

	// Init

//	public function new()
//	{
//		super();
//	}
	
	override private function init():Void
	{
		super.init();
		
		startScreenClass = MenuScreen;
		host = "localhost";
		port = 5555;

		// For switching protocol version
		// (Get versions)
		var parser = ioc.create(CustomMultiParser);
		versions = parser.versions;

		keyControl = ioc.create(KeyControl);
		keyControl.skin = this;
		// Listeners
		keyControl.keyUpSignal.add(keyControl_keyUpSignalHandler);
	}
	
	override private function configureApp():Void
	{
		super.configureApp();
		
		// Note: Using interfaces we can substitute some class without extending it, 
		// but only implementing the same interface.
		ioc.register(IDresserController, DresserController);
		ioc.register(IColoringModel, ColoringModel);
		ioc.register(IColoringController, ColoringController);
		ioc.register(IProtocol, CustomProtocol);
		ioc.register(ICustomProtocol0, CustomProtocol);
		ioc.register(ICustomProtocol, CustomProtocol);
		ioc.register(ITransport, SocketTransport);
		ioc.register(IParser, CustomMultiParser);
	}

	override public function dispose():Void
	{
		// Listeners
		keyControl.keyUpSignal.remove(keyControl_keyUpSignalHandler);
		keyControl.dispose();
		
		super.dispose();
	}

	// Handlers

	private function keyControl_keyUpSignalHandler(event:KeyboardEvent):Void
	{
		if (event.keyCode >= Keyboard.NUMBER_1 && event.keyCode <= Keyboard.NUMBER_9)
		{
			var index = event.keyCode - Keyboard.NUMBER_1;
			var version = versions[index];
			Log.debug('SET VERSIONS: $versions');
			for (v in versions)
			{
				// Send multiple version messages at once
				protocol.version = v;
			}
			protocol.version = version;
		}

		// (To enable client buffer for testing server buffer)
		var isPlus = event.keyCode == Keyboard.NUMPAD_ADD;
		if (isPlus || event.keyCode == Keyboard.NUMPAD_SUBTRACT)
		{
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
