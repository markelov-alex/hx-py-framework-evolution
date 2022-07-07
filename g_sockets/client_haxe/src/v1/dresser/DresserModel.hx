package v1.dresser;

import haxe.Exception;
import haxe.Json;
import openfl.events.DataEvent;
import openfl.events.Event;
import openfl.net.XMLSocket;
import v0.lib.ArrayUtil;
import v0.lib.IoC;
import v0.lib.Log;
import v0.lib.Signal;

/**
 * DresserModel.
 * 
 */
class DresserModel
{
	// Settings

	// State

	private var socket:XMLSocket;

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
		socket = IoC.getInstance().getSingleton(XMLSocket);
		// Listeners
		socket.addEventListener(Event.CONNECT, socket_connectHandler);
		socket.addEventListener(DataEvent.DATA, socket_dataHandler);

		// For model created after connected
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

	private function send(data:Dynamic):Void
	{
		Log.debug('<< Send: $data');
		socket.send(Json.stringify(data));
	}

	private function processCommands(commands:Array<Dynamic>):Void
	{
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

	private function socket_connectHandler(event:Event):Void
	{
		// On reconnect
		load();
	}

	private function socket_dataHandler(event:DataEvent):Void
	{
		try
		{
			var data = Json.parse(event.data);
			var commands:Array<Dynamic> = Std.isOfType(data, Array) ? data : [data];
			processCommands(commands);
		}
		catch (e:Exception)
		{
			Log.error(e);
		}
	}
}
