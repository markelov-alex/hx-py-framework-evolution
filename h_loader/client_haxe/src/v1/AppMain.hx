package v1;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v0.coloring.ColoringController;
import v0.coloring.ColoringModel;
import v0.coloring.ColoringScreen;
import v0.coloring.IColoringController;
import v0.coloring.IColoringModel;
import v0.dresser.DresserController;
import v0.dresser.DresserScreen;
import v0.dresser.IDresserController;
import v0.lib.components.Resizer.StageResizer;
import v0.lib.components.Screen;
import v0.lib.net.IProtocol;
import v0.lib.net.parser.IParser;
import v0.lib.net.transport.ITransport;
import v0.lib.net.transport.SocketTransport;
import v0.lib.util.Log;
import v0.menu.MainMenu;
import v0.menu.MenuScreen;
import v0.net.ICustomProtocol;
import v1.lib.components.KeyControl;
import v1.lib.components.StageResizer2;
import v1.lib.GameApplication;
import v1.menu.MenuScreen;
import v1.net.CustomProtocol;
import v1.net.parser.CustomMultiParser;

/**
 * AppMain.
 * 
 * Changes:
 *  - extract Application from Main,
 *  - add stageWidth, stageHeight to Application for using in StageResizer,
 *  - add Application reference to Resizer as another source of stageWidth, stageHeight.
 */
class AppMain extends GameApplication
{
	// Settings

	public var screenClassBySubRoomName:Map<String, Class<Screen>> = [
		"lobby" => MenuScreen,
		"dresser" => DresserScreen,
		"coloring" => ColoringScreen,
	];

	// State
	
	private var versions:Array<String>;
	private var keyControl:KeyControl;

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

		var protocol:v1.net.ICustomProtocol = Std.downcast(this.protocol, v1.net.ICustomProtocol);
		if (protocol != null)
		{
			// Listeners
			protocol.gotoSignal.add(protocol_gotoSignalHandler);
		}
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
		ioc.register(StageResizer, StageResizer2);
		
		ioc.register(MainMenu, v1.menu.MainMenu);
		ioc.register(MenuScreen, v1.menu.MenuScreen);
		ioc.register(DresserScreen, v1.dresser.DresserScreen);
		ioc.register(ColoringScreen, v1.coloring.ColoringScreen);
	}

	override public function dispose():Void
	{
		keyControl.dispose();
		var protocol:v1.net.ICustomProtocol = Std.downcast(this.protocol, v1.net.ICustomProtocol);
		if (protocol != null)
		{
			// Listeners
			protocol.gotoSignal.remove(protocol_gotoSignalHandler);
		}
		
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

	private function protocol_gotoSignalHandler(roomName:String):Void
	{
		if (roomName != null)
		{
			for (subRoomName => screenClass in screenClassBySubRoomName)
			{
				if (roomName.indexOf(subRoomName) != -1)
				{
					screens.open(screenClass);
					break;
				}
			}
		}
	}
}
