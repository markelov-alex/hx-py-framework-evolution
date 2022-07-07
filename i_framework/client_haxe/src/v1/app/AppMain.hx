package v1.app;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v1.app.menu.MenuScreen;
import v1.app.net.CustomProtocol;
import v1.app.net.ICustomProtocol;
import v1.app.net.parser.CustomMultiParser;
import v1.framework.ui.controls.KeyControl;
import v1.framework.ui.dialogs.ConfirmDialog;
import v1.framework.ui.dialogs.SettingsDialog;
import v1.framework.GameApplication;
import v1.framework.net.IProtocol;
import v1.framework.net.parser.IParser;
import v1.framework.net.transport.ITransport;
import v1.framework.net.transport.SocketTransport;
import v1.framework.util.Log;
import v1.lib.coloring.ColoringController;
import v1.lib.coloring.ColoringModel;
import v1.lib.coloring.IColoringController;
import v1.lib.coloring.IColoringModel;
import v1.lib.dresser.DresserController;
import v1.lib.dresser.IDresserController;

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
		ioc.register(ICustomProtocol, CustomProtocol);
		ioc.register(ITransport, SocketTransport);
		ioc.register(IParser, CustomMultiParser);
		ioc.register(SettingsDialog, v1.app.dialogs.SettingsDialog);
		ioc.register(ConfirmDialog, v1.app.dialogs.ConfirmDialog);
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
