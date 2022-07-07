package v3.lib;

import haxe.Exception;
import haxe.Json;
import haxe.Timer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;
import v0.lib.Log;

/**
 * Request.
 * 
 */
class Request
{
	// Settings

	private var url:String;
	private var callback:Dynamic->Void;
	
	// State
	
	private var loader:URLLoader;
	
	// Methods
	
	public function new()
	{
	}
	
	public function send(url:String, ?data:Dynamic, ?callback:Dynamic->Void,
						 method:String=URLRequestMethod.GET):Void
	{
		// Stop current if any
		dispose();
		this.url = url;
		this.callback = callback;
		var request = new URLRequest(url);
		//request.method = method; // Doesn't work for anything except GET and POST
		request.data = new URLVariables();
		request.data._method = method; // Workaround
		request.data.antiCache = Timer.stamp();
		request.data.data = Json.stringify(data);
		loader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, loader_completeHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
		loader.load(request);
	}
	
	public function dispose():Void
	{
		url = null;
		callback = null;
		if (loader != null)
		{
			try
			{
				loader.close();
			}
			catch (e:Exception)
			{}
			loader.removeEventListener(Event.COMPLETE, loader_completeHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loader_ioErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loader_securityErrorHandler);
			loader = null;
		}
	}
	
	// Handlers

	private function loader_completeHandler(event:Event):Void
	{
		if (callback != null)
		{
			var loader:URLLoader = cast(event.currentTarget, URLLoader);
			callback(loader.data);
		}
		dispose();
	}
	
	private function loader_ioErrorHandler(event:IOErrorEvent):Void
	{
		Log.error('Request fail $event');
		dispose();
	}
	
	private function loader_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		Log.error('Request fail (security) $event.');
		dispose();
	}
}
