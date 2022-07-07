package v3.dresser;

import v0.lib.ArrayUtil;
import v0.lib.Signal;
import v2.dresser.IDresserProtocol;
import v3.lib.net.JSONSocketProtocol;
import v3.lib.net.transport.ITransport;

/**
 * DresserProtocol.
 * 
 * Changes:
 *  - just extend another Protocol class.
 */
class DresserProtocol extends JSONSocketProtocol implements IDresserProtocol
{
	// Settings

	// State

	public var state(default, set):Array<Int> = [];
	public function set_state(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(state, value))
		{
			state = value;
			// Dispatch
			stateChangeSignal.dispatch(value);
		}
		return value;
	}

	// Signals

	public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

	// Init

	public function new()
	{
		super();

		// For protocol created after connected
		load();
	}

	// Methods

	public function load():Void
	{
		send({command: "get", name: "dresserState"});
	}

	public function changeItem(itemIndex:Int, frame:Int):Void
	{
		var data = {};
		Reflect.setField(data, Std.string(itemIndex), frame);
		send({
			command: "update",
			name: "dresserState",
			data: data
		});
	}

	override private function processCommands(commands:Array<Dynamic>):Void
	{
		super.processCommands(commands);
		
		for (command in commands)
		{
			if (command.command == "set")
			{
				if (command.name == "dresserState")
				{
					state = command.data;
				}
			}
			else if (command.command == "update")
			{
				if (command.name == "dresserState")
				{
					for (ii in Reflect.fields(command.data))
					{
						var itemIndex = Std.parseInt(ii);
						var frame = Reflect.field(command.data, ii);

						// Update model
						state[itemIndex] = frame;

						// Dispatch
						itemChangeSignal.dispatch(itemIndex, frame);
					}
				}
			}
		}
	}

	// Handlers

	override private function transport_connectedSignalHandler(target:ITransport):Void
	{
		super.transport_connectedSignalHandler(target);
		// On reconnect
		load();
	}
}
