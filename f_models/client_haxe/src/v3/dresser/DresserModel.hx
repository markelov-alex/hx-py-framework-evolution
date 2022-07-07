package v3.dresser;

import haxe.Exception;
import haxe.Json;
import haxe.Timer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.net.URLRequestHeader;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;
import v0.lib.ArrayUtil;
import v0.lib.Log;
import v0.lib.Signal;

/**
 * DresserModel.
 * 
 */
class DresserModel
{
	// Settings

	public var url = "http://127.0.0.1:5000/storage/dresser";

	// State

	private var _state:Array<Int> = [];
	@:isVar
	public var state(get, set):Array<Int>;
	public function get_state():Array<Int>
	{
		return _state;
	}
	public function set_state(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(_state, value))
		{
			send({state: value}, function (data:Dynamic):Void {
				_state = data.state;
				stateChangeSignal.dispatch(data.state);
			}, URLRequestMethod.POST);
		}
		return value;
	}

	// Signals

	public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

	// Init

	public function new()
	{
		Log.info('$this v3');
	}

	// Methods
	
	public function load():Void
	{
		send(null, function (data:Dynamic):Void {
			_state = data.state;
			stateChangeSignal.dispatch(data.state);
		});
	}
	
	public function changeItem(index:Int, value:Int):Void
	{
		if (state[index] != value)
		{
			send({index: index, value: value}, function (data:Dynamic):Void {
				state[data.index] = data.value;
				itemChangeSignal.dispatch(data.index, data.value);
			}, "PATCH");
		}
	}
	
	private function send(?data:Dynamic, ?callback:Dynamic->Void,
						  method:String=URLRequestMethod.GET):Void
	{
		var request = new URLRequest(url);
		//request.method = method; // Doesn't work for anything except GET and POST
		// Also doesn't work
		request.requestHeaders.push(new URLRequestHeader("X-METHOD-OVERRIDE", method));
		request.data = new URLVariables();
		request.data._method = method;
		request.data.antiCache = Timer.stamp();
		request.data.data = Json.stringify(data);
		var loader = new URLLoader();
		var loader_ioErrorHandler;
		var loader_securityErrorHandler;
		function loader_completeHandler(event:Event):Void
		{
			Log.debug('Request complete ${loader.data}');
			loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
			var data = parseResponseFrom(event);
			if (callback != null)
			{
				callback(data);
			}
		}
		loader_ioErrorHandler = function (event:IOErrorEvent):Void
		{
			Log.error('Request fail $event');
			loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
		}
		loader_securityErrorHandler = function (event:SecurityErrorEvent):Void
		{
			Log.error('Request fail (security) $event.');
			loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
		}
		loader.addEventListener(Event.COMPLETE, loader_completeHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
		loader.load(request);
	}
	
	private function parseResponseFrom(event:Event):Dynamic
	{
		var loader:URLLoader = cast(event.currentTarget, URLLoader);
		Log.debug('Parse data: ${loader.data} from url: $url');
		try
		{
			var data:Dynamic = Json.parse(loader.data);
			Log.debug(' Parsed state data: $data from url: $url');
			return data;
		}
		catch (e:Exception)
		{
			Log.error('Parsing error: $e');
		}
		return null;
	}
}
