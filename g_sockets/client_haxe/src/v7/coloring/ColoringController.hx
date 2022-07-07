package v7.coloring;

import v7.lib.IoC;
import v7.lib.net.IProtocol;
import v7.lib.util.Signal;
import v7.net.ICustomProtocol;

/**
 * ColoringController.
 * 
 */
class ColoringController implements IColoringController
{
	// Settings

	// State

	private var model:IColoringModel;
	
	public var protocol(default, set):ICustomProtocol;
	public function set_protocol(value:ICustomProtocol):ICustomProtocol
	{
		var protocol = this.protocol;
		if (protocol != value)
		{
			if (protocol != null)
			{
				// Listeners
				protocol.connectedSignal.remove(protocol_connectedSignalHandler);
				protocol.setDataSignal.remove(protocol_setDataSignalHandler);
				protocol.updateDataSignal.remove(protocol_updateDataSignalHandler);
			}

			this.protocol = protocol = value;
			
			if (protocol != null)
			{
				// Listeners
				protocol.connectedSignal.add(protocol_connectedSignalHandler);
				protocol.setDataSignal.add(protocol_setDataSignalHandler);
				protocol.updateDataSignal.add(protocol_updateDataSignalHandler);
			}
		}
		return value;
	}
	
	// Signals

	public var applyColorSignal(default, null) = new Signal2<Int, Int>();
	
	// Init

	public function new()
	{
		// State
		var ioc = IoC.getInstance();
		model = ioc.getSingleton(IColoringModel);
		protocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
		
		if (protocol.isConnected)
		{
			load();
		}
	}

	public function dispose():Void
	{
		model = null;
		protocol = null;
	}

	// Methods

	public function load():Void
	{
		protocol.load("pictureStates");
	}

	public function applyColor(itemIndex:Int, color:Int):Void
	{
		// Prepare data
		var item = {};
		Reflect.setField(item, Std.string(itemIndex), color);
		var data = {};
		Reflect.setField(data, Std.string(model.pictureIndex), item);
		// Send
		protocol.update("pictureStates", data);
	}
	
	// Handlers

	private function protocol_connectedSignalHandler(protocol:IProtocol):Void
	{
		load();
	}

	private function protocol_setDataSignalHandler(name:String, data:Dynamic):Void
	{
		if (name != "pictureStates")
		{
			return;
		}
		
		model.pictureStates = data;
	}

	private function protocol_updateDataSignalHandler(name:String, data:Dynamic):Void
	{
		if (name != "pictureStates")
		{
			return;
		}

		for (pi in Reflect.fields(data))
		{
			var pictureIndex = Std.parseInt(pi);
			var pictureData = Reflect.field(data, pi);
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
