package v0.net;

import v0.lib.net.transport.ITransport;
import v0.lib.util.Signal;
import v0.net.ICustomProtocol;
import v0.coloring.ColoringScreen;
import v0.dresser.DresserScreen;
import v0.lib.components.Screen;
import v0.lib.components.Screens;
import v0.lib.net.Protocol2;
import v0.menu.MenuScreen;

/**
 * CustomProtocol.
 * 
 */
class CustomProtocol extends Protocol2 implements ICustomProtocol
{
	// Settings

	public var defaultRoomName = "lobby";
	public var screenClassBySubRoomName:Map<String, Class<Screen>> = [
		"lobby" => MenuScreen,
		"dresser" => DresserScreen,
		"coloring" => ColoringScreen,
	];
	
	// State
	
	private var screens:Screens;
	
	// Signals

	public var setDataSignal(default, null) = new Signal2<String, Dynamic>();
	public var updateDataSignal(default, null) = new Signal2<String, Dynamic>();
	public var gotoSignal(default, null) = new Signal<String>();

	// Init

	public function new():Void
	{
		super();

		// Settings
		defaultVersion = "v.1.0.0";
		//transportType = SocketTransport;
		//parserType = CustomMultiParser;
	}

	override private function init():Void
	{
		super.init();
		
		screens = ioc.getSingleton(Screens);
	}

	override public function dispose():Void
	{
		setDataSignal.dispose();
		updateDataSignal.dispose();
		gotoSignal.dispose();
		
		super.dispose();
	}

	// Methods

	public function load(name:String):Void
	{
		send({command: "get", name: name});
	}

	public function update(name:String, data:Dynamic):Void
	{
		send({
			command: "update",
			name: name,
			data: data
		});
	}

	public function goto(name:String):Void
	{
		send({
			command: "goto",
			name: name,
		});
	}

	override private function processCommand(command:Dynamic):Void
	{
		super.processCommand(command);

		// All data should be parsed and transformed in parser and in here. 
		// As protocol uses data from application without changes, no additional 
		// transformations needed. 
		if (command.command == "set")
		{
			// Dispatch
			setDataSignal.dispatch(command.name, command.data);
		}
		else if (command.command == "update")
		{
			// Dispatch
			updateDataSignal.dispatch(command.name, command.data);
		}
		else if (command.command == "goto")
		{
			var roomName:String = command.name;
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
			// Dispatch
			gotoSignal.dispatch(command.name);
		}
	}

	// Handlers

	override private function transport_disconnectedSignalHandler(target:ITransport):Void
	{
		super.transport_disconnectedSignalHandler(target);
		
		processCommand({command: "goto", name: defaultRoomName});
	}
}
