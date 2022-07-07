package v3.coloring;

import haxe.Exception;
import haxe.Json;
import openfl.net.SharedObject;
import openfl.net.URLRequestMethod;
import v0.lib.Log;
import v3.lib.Request;

/**
 * ColoringModel.
 * 
 */
class ColoringModel extends v1.coloring.ColoringModel
{
	// Settings
	
	public var url = "http://127.0.0.1:5000/storage/coloring";
	public var useShared = false;

	// State
	
	private var shared = SharedObject.getLocal("coloring");

	override public function set_pictureIndex(value:Int):Int
	{
		if (useShared)
		{
			shared.data.pictureIndex = value;
		}
		if (pictureIndex != value)
		{
			// Load data changed by another app instance
			load();
			super.set_pictureIndex(value);
		}
		return pictureIndex;
	}

	override public function set_colorIndex(value:Int):Int
	{
		if (useShared)
		{
			shared.data.colorIndex = value;
		}
		return super.set_colorIndex(value);
	}

	// Init

	public function new()
	{
		super();

		Log.info('$this v3');
		if (useShared)
		{
			pictureIndex = shared.data.pictureIndex;
			colorIndex = shared.data.colorIndex;
		}
	}

	// Methods
	
	public function load():Void
	{
		new Request().send(url, null, function (response:Dynamic):Void {
			var data = parseResponse(response);
			if (data.success)
			{
				pictureStates = data.state;
			}
		});
	}
	
	public function save():Void
	{
		// Save pictureStates on server
		if (pictureStates != null)
		{
			var data = {state: pictureStates};
			new Request().send(url, data, null, URLRequestMethod.POST);
		}
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

