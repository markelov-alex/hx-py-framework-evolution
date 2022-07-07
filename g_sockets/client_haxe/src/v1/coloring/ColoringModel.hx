package v1.coloring;

import haxe.Exception;
import haxe.Json;
import openfl.events.DataEvent;
import openfl.events.Event;
import openfl.net.XMLSocket;
import v0.lib.ArrayUtil;
import v0.lib.IoC;
import v0.lib.Log;
import v0.lib.Signal;

interface IColoringModel
{
	// Settings
	
	public var defaultColor:Int;
	public var colors:Array<Int>;
	public var maxPictureIndex:Int;
	
	// State
	
	public var state(get, set):ColoringState;
	public var pictureStates(default, set):Array<Array<Int>>;
	public var pictureIndex(default, set):Int;
	public var currentPictureState(default, set):Array<Int>;
	public var colorIndex(default, set):Int;
	public var color(default, null):Int;

	// Signals

	public var pictureChangeSignal(default, null):Signal<Int>;
	public var currentPictureStateChangeSignal(default, null):Signal<Array<Int>>;
	public var colorChangeSignal(default, null):Signal<Int>;
}

/**
 * ColoringModel.
 * 
 */
class ColoringModel implements IColoringModel
{
	// Settings

	public var defaultColor:Int = 0xF5DEB3;
	public var colors:Array<Int> = [
		0xEC7063, 0xAF7AC5, 0x85C1E9, 0x52BE80, 0x58D68D, 0xF4D03F, 0xF5B041, 0xCACFD2, 0xD7DBDD, 0x5D6D7E,
		0xCB4335, 0x6C3483, 0x1F618D, 0x1E8449, 0x239B56, 0xB8860B, 0xCA6F1E, 0x909497, 0x616A6B, 0x212F3D
	];
	public var maxPictureIndex = 0;

	// State
	
	private var socket:XMLSocket;

	/**
	 * To save and load the whole game state.
	 */
	@:isVar
	public var state(get, set):ColoringState;
	public function get_state():ColoringState
	{
		return {
			"pictureStates": pictureStates,
			"pictureIndex": pictureIndex,
			"colorIndex": colorIndex,
		};
	}
	public function set_state(value:ColoringState):ColoringState
	{
		if (state != value)
		{
			state = value;
			if (value != null)
			{
				// Set pictureStates first for pictureIndex setter to update currentPictureState
				pictureStates = value.pictureStates != null ? value.pictureStates : [];
				pictureIndex = value.pictureIndex;
				colorIndex = value.colorIndex;
			}
		}
		return value;
	}

	public var pictureStates(default, set):Array<Array<Int>> = [];
	public function set_pictureStates(value:Array<Array<Int>>):Array<Array<Int>>
	{
		if (value == null)
		{
			value = [];
		}
		pictureStates = value;
		// Refresh currentPictureState
		currentPictureState = pictureStates[pictureIndex];
		return pictureStates;
	}
	
	public var pictureIndex(default, set):Int = 0;
	public function set_pictureIndex(value:Int):Int
	{
		if (value >= maxPictureIndex)
		{
			value = maxPictureIndex - 1;
		}
		if (value < 0)
		{
			value = 0;
		}
		if (pictureIndex != value)
		{
			pictureIndex = value;

			// Refresh currentPictureState
			currentPictureState = pictureStates[value];
			
			// Dispatch
			pictureChangeSignal.dispatch(value);
		}
		return value;
	}
	
	public var currentPictureState(default, set):Array<Int>;
	public function set_currentPictureState(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(currentPictureState, value))
		{
			currentPictureState = value;
			
			// Refresh game state
			pictureStates[pictureIndex] = value;
			
			// Dispatch
			currentPictureStateChangeSignal.dispatch(value);
		}
		return value;
	}

	public var colorIndex(default, set):Int = -1;
	public function set_colorIndex(value:Int):Int
	{
		var colorIndex = this.colorIndex;
		if (colorIndex != value)
		{
			this.colorIndex = colorIndex = value;

			color = if (colorIndex < 0 || colorIndex >= colors.length)
				defaultColor else colors[colorIndex];

			// Dispatch
			colorChangeSignal.dispatch(value);
		}
		return value;
	}
	
	public var color(default, null):Int;

	// Signals

	public var pictureChangeSignal(default, null) = new Signal<Int>();
	public var currentPictureStateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var colorChangeSignal(default, null) = new Signal<Int>();
	
	public var applyColorSignal(default, null) = new Signal2<Int, Int>();

	// Init

	public function new()
	{
		colorIndex = 0;
		
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
		Reflect.setField(data, Std.string(pictureIndex), item);
		send({
			command: "update", 
			name: "pictureStates", 
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
				if (command.name == "pictureStates")
				{
					pictureStates = command.data;
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
						var ps = pictureStates[pictureIndex];
						if (ps == null)
						{
							ps = pictureStates[pictureIndex] = [];
						}
						for (ii in Reflect.fields(pictureData))
						{
							var itemIndex = Std.parseInt(ii);
							var color = Reflect.field(pictureData, ii);
							
							// Update model
							ps[itemIndex] = color;
	
							// Dispatch
							if (pictureIndex == this.pictureIndex)
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

typedef ColoringState = {
	var pictureStates:Array<Array<Int>>;
	var pictureIndex:Int;
	var colorIndex:Int;
}
