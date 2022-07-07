package v4;

import haxe.Exception;
import haxe.Json;
import openfl.net.URLRequestMethod;
import v0.lib.Log;
import v0.lib.Signal;
import v3.lib.Request;

/**
 * StorageService.
 * 
 */
class StorageService implements IStorageService
{
	// Settings

	public var url = "http://127.0.0.1:5000/storage/";

	// State

	// Signals

	public var loadSignal(default, null) = new Signal<Dynamic>();
	public var stateChangeSignal(default, null) = new Signal<Dynamic>();
	public var itemChangeSignal(default, null) = new Signal2<Dynamic, Dynamic>();

	// Init

	public function new()
	{
		Log.info('$this v4');
	}

	// Methods

	public function load():Void
	{
		new Request().send(url, null, function (response:Dynamic):Void {
			var data = parseResponse(response);
			if (data.success)
			{
				// Dispatch
				loadSignal.dispatch(data.state);
			}
		});
	}
	
	public function setState(value:Dynamic):Void
	{
		new Request().send(url, {state: value}, function (response:Dynamic):Void {
			var data = parseResponse(response);
			if (data.success)
			{
				// Dispatch
				stateChangeSignal.dispatch(data.state);
			}
		}, URLRequestMethod.POST);
	}
	
	public function changeItem(index:Dynamic, value:Dynamic):Void
	{
		new Request().send(url, {index: index, value: value}, function (response:Dynamic):Void {
			var data = parseResponse(response);
			if (data.success)
			{
				// Dispatch
				itemChangeSignal.dispatch(data.index, data.value);
			}
		}, "PATCH");
	}
	
	private function parseResponse(response:Dynamic):Dynamic
	{
		Log.debug('Load data: ${response} from url: $url');
		try
		{
			var data:Dynamic = Json.parse(response);
			Log.debug(' Loaded state data: ${data} from url: $url');
			return data;
		}
		catch (e:Exception)
		{
			Log.error('Parsing error: $e');
		}
		return null;
	}
}
