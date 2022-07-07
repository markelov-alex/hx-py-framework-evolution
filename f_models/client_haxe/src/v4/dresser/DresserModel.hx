package v4.dresser;

import openfl.net.URLRequestMethod;
import v0.lib.ArrayUtil;
import v0.lib.IoC;
import v0.lib.Log;

/**
 * DresserModel.
 * 
 */
class DresserModel extends v3.dresser.DresserModel
{
	// Settings

	// State
	
	private var service:IStorageService;

	override public function set_state(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(_state, value))
		{
			service.setState(value);
		}
		return value;
	}
	
	// Init

	public function new()
	{
		super();
		init();
		// Listeners
		service.loadSignal.add(service_loadSignalHandler);
		service.stateChangeSignal.add(service_stateChangeSignalHandler);
		service.itemChangeSignal.add(service_itemChangeSignalHandler);
	}

	private function init():Void
	{
		service = IoC.getInstance().create(DresserService);
	}

	// Methods

	override public function load():Void
	{
		service.load();
	}

	override public function changeItem(index:Int, value:Int):Void
	{
		if (state[index] != value)
		{
			service.changeItem(index, value);
		}
	}

	// Disable previous version
	override private function send(?data:Dynamic, ?callback:Dynamic->Void,
						  			method:String=URLRequestMethod.GET):Void
	{
	}

	// Handlers

	private function service_loadSignalHandler(value:Dynamic):Void
	{
		_state = value != null ? cast value : [];
		// Dispatch
		stateChangeSignal.dispatch(value);
	}
	
	private function service_stateChangeSignalHandler(value:Dynamic):Void
	{
		_state = value != null ? cast value : [];
		// Dispatch
		stateChangeSignal.dispatch(value);
	}
	
	private function service_itemChangeSignalHandler(index:Dynamic, value:Dynamic):Void
	{
		state[index] = cast value;
		// Dispatch
		itemChangeSignal.dispatch(index, value);
	}
}
