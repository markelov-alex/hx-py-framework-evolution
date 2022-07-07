package v2.coloring;

import openfl.events.Event;
import v0.lib.IoC;
import v0.lib.Signal;
import v2.lib.net.Protocol;

/**
 * ColoringProtocol.
 * 
 * To do: move ColoringModel getter for all components here (in further versions).
 */
class ColoringProtocol extends Protocol implements IColoringProtocol
{
	// Settings

	// State
	
	private var model:ColoringModel;

	// Signals

	public var applyColorSignal(default, null) = new Signal2<Int, Int>();

	// Init

	public function new()
	{
		super();

		model = IoC.getInstance().getSingleton(ColoringModel);

		// For protocol created after connected
		load();
	}

	override public function dispose():Void
	{
		super.dispose();
		model = null;
	}

	// Methods

	public function load():Void
	{
		send({command: "get", name: "pictureStates"});
	}

//	public function loadCurrent():Void
//	{
//		send({command: "get", name: 'pictureStates.$pictureIndex'});
//	}

	public function applyColor(itemIndex:Int, color:Int):Void
	{
		var item = {};
		Reflect.setField(item, Std.string(itemIndex), color);
		var data = {};
		Reflect.setField(data, Std.string(model.pictureIndex), item);
		send({
			command: "update",
			name: "pictureStates",
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
				if (command.name == "pictureStates")
				{
					model.pictureStates = command.data;
				}
			}
			else if (command.command == "update")
			{
				if (command.name == "pictureStates")
				{
					for (pi in Reflect.fields(command.data))
					{
						var pictureIndex = Std.parseInt(pi);
						var pictureData = Reflect.field(command.data, pi);
						var ps = model.pictureStates[pictureIndex];
						if (ps == null)
						{
							ps = model.pictureStates[pictureIndex] = [];
						}
						for (ii in Reflect.fields(pictureData))
						{
							var itemIndex = Std.parseInt(ii);
							var color = Reflect.field(pictureData, ii);

							// Update model
							ps[itemIndex] = color;

							// Dispatch
							if (pictureIndex == model.pictureIndex)
							{
								applyColorSignal.dispatch(itemIndex, color);
							}
						}
					}
				}
			}
		}
	}

	// Handlers

	override private function socket_connectHandler(event:Event):Void
	{
		super.socket_connectHandler(event);
		// On reconnect
		load();
	}
}
