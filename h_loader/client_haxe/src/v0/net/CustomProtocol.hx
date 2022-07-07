package v0.net;

import v0.lib.net.Protocol2;
import v0.lib.util.Signal;

/**
 * CustomProtocol.
 * 
 */
class CustomProtocol extends Protocol2 implements ICustomProtocol
{
	// Settings

	// State
	
	// Signals

	public var setDataSignal(default, null) = new Signal2<String, Dynamic>();
	public var updateDataSignal(default, null) = new Signal2<String, Dynamic>();

	// Init

	override private function init():Void
	{
		super.init();
		
		// Settings
		defaultVersion = "v.1.0.0";
		//transportType = SocketTransport;
		//parserType = CustomMultiParser;
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
	}
}
