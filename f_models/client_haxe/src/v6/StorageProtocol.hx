package v6;

import v0.lib.Log;
import v0.lib.Signal;
import v4.IStorageService;
import v5.lib.Request;
import v6.lib.Protocol;

/**
 * StorageService.
 * 
 * Changes:
 *  - use final version of Request.
 */
class StorageProtocol extends Protocol implements IStorageService
{
	// Settings

	// State

	// Signals

	public var loadSignal(default, null) = new Signal<Dynamic>();
	public var stateChangeSignal(default, null) = new Signal<Dynamic>();
	public var itemChangeSignal(default, null) = new Signal2<Dynamic, Dynamic>();

	// Methods

	public function new()
	{
		super();
		Log.info('$this v6');
	}
	
	public function load():Void
	{
		send({command: "get"});
	}

	public function setState(value:Dynamic):Void
	{
		send({state: value, command: "save"});
	}

	public function changeItem(index:Dynamic, value:Dynamic):Void
	{
		send({index: index, value: value, command: "update"});
	}

	// Handlers

	override private function processData(data:Dynamic):Void
	{
		super.processData(data);
		
		var code = data.command != null ? data.command : data._method;
		if (data.version != "v6") // code == null)
		{
			Log.error('Use "v6" version of server! data: $data');
		}
		
		// Note: "GET", "POST", "PATCH" for HTTP server v5
		// "get", "save", "update" for HTTP server v6 and all Socket servers
		switch code
		{
			case "get": // | "GET" | null:
				// Dispatch
				loadSignal.dispatch(data.state);
			case "save" | "set": // | "POST":
				// Dispatch
				stateChangeSignal.dispatch(data.state);
			case "update": // | "PATCH":
				// Dispatch
				itemChangeSignal.dispatch(data.index, data.value);
		}
	}
}
