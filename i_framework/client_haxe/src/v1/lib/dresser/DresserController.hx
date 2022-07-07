package v1.lib.dresser;

import v1.lib.dresser.IDresserController;
import v1.framework.Base;
import v1.framework.net.IProtocol;
import v1.framework.util.ArrayUtil;
import v1.framework.util.Signal.Signal2;
import v1.framework.util.Signal;
import v1.app.net.ICustomProtocol;

/**
 * DresserController.
 * 
 */
class DresserController extends Base implements IDresserController
{
	// Settings

	// State
	
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

	override private function init():Void
	{
		super.init();
		
		protocol = Std.downcast(ioc.getSingleton(IProtocol), ICustomProtocol);
		if (protocol != null && protocol.isConnected)
		{
			load();
		}
	}

	override public function dispose():Void
	{
		stateChangeSignal.dispose();
		itemChangeSignal.dispose();
		
		protocol = null;
		
		super.dispose();
	}

	// Methods

	public function load():Void
	{
		protocol.load("dresserState");
	}

	public function changeItem(itemIndex:Int, frame:Int):Void
	{
		// Prepare data
		var data = {};
		Reflect.setField(data, Std.string(itemIndex), frame);
		// Send
		protocol.update("dresserState", data);
	}
	
	// Handlers

	private function protocol_connectedSignalHandler(protocol:IProtocol):Void
	{
		load();
	}

	private function protocol_setDataSignalHandler(name:String, data:Dynamic):Void
	{
		if (name != "dresserState")
		{
			return;
		}

		state = data;
	}

	private function protocol_updateDataSignalHandler(name:String, data:Dynamic):Void
	{
		if (name != "dresserState")
		{
			return;
		}

		for (ii in Reflect.fields(data))
		{
			var itemIndex = Std.parseInt(ii);
			var frame = Reflect.field(data, ii);

			// Update model
			state[itemIndex] = frame;

			// Dispatch
			itemChangeSignal.dispatch(itemIndex, frame);
		}
	}
}
