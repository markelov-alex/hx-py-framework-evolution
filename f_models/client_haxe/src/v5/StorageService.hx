package v5;

import haxe.Json;
import v0.lib.Log;
import v0.lib.Signal;
import v4.IStorageService;
import v5.lib.Request;

/**
 * StorageService.
 * 
 * Changes:
 *  - use final version of Request.
 */
class StorageService implements IStorageService
{
	// Settings

	public var url = "http://127.0.0.1:5000/storage/";

	// State
	
	private var loadRequest = new Request();
	private var stateChangeRequest = new Request();
	private var itemChangeRequest = new Request();

	// Signals

	public var loadSignal(default, null) = new Signal<Dynamic>();
	public var stateChangeSignal(default, null) = new Signal<Dynamic>();
	public var itemChangeSignal(default, null) = new Signal2<Dynamic, Dynamic>();

	// Init

	public function new()
	{
		Log.info('$this v5');
		loadRequest.callback = onLoad;
		loadRequest.format = Format.JSON;
		stateChangeRequest.callback = onSetState;
		stateChangeRequest.format = Format.JSON;
		itemChangeRequest.callback = onChangeItem;
		itemChangeRequest.format = Format.JSON;
	}

	// Methods

	public function load():Void
	{
		loadRequest.send(null, url);
	}

	public function setState(value:Dynamic):Void
	{
		var plainData = Json.stringify({state: value});
		stateChangeRequest.send(Method.POST, url, ["data" => plainData]);
	}

	public function changeItem(index:Dynamic, value:Dynamic):Void
	{
		var plainData = Json.stringify({index: index, value: value});
		itemChangeRequest.send(Method.PATCH, url, ["data" => plainData]);
	}

	// Handlers

	private function onLoad(data:Dynamic):Void
	{
		if (data.success)
		{
			// Dispatch
			loadSignal.dispatch(data.state);
		}
	}

	private function onSetState(data:Dynamic):Void
	{
		if (data.success)
		{
			// Dispatch
			stateChangeSignal.dispatch(data.state);
		}
	}

	private function onChangeItem(data:Dynamic):Void
	{
		if (data.success)
		{
			// Dispatch
			itemChangeSignal.dispatch(data.index, data.value);
		}
	}
}
