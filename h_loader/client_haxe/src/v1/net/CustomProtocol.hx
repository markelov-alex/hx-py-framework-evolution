package v1.net;

import v0.lib.net.transport.ITransport;
import v0.lib.util.Signal;
import v0.net.CustomProtocol as CustomProtocol0;

/**
 * CustomProtocol.
 * 
 */
class CustomProtocol extends CustomProtocol0 implements ICustomProtocol
{
	// Settings

	public var defaultRoomName = "lobby";

	// State
	
	// Signals

	public var gotoSignal(default, null) = new Signal<String>();

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

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

		if (command.command == "goto")
		{
			var roomName:String = command.name;
			// Dispatch
			gotoSignal.dispatch(roomName);
		}
	}

	// Handlers

	override private function transport_disconnectedSignalHandler(target:ITransport):Void
	{
		super.transport_disconnectedSignalHandler(target);

		processCommand({command: "goto", name: defaultRoomName});
	}
}
