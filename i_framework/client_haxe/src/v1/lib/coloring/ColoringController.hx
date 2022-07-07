package v1.lib.coloring;

import v1.lib.coloring.IColoringController;
import v1.lib.coloring.IColoringModel;
import v1.framework.Base;
import v1.framework.net.IProtocol;
import v1.framework.util.Signal;
import v1.app.net.ICustomProtocol;

/**
 * ColoringController.
 * 
 */
class ColoringController extends Base implements IColoringController
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

	override private function init():Void
	{
		super.init();

		model = ioc.getSingleton(IColoringModel);
		protocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
		if (protocol != null && protocol.isConnected)
		{
			load();
		}
	}

	override public function dispose():Void
	{
		applyColorSignal.dispose();
		
		model = null;
		protocol = null;
		
		super.dispose();
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
