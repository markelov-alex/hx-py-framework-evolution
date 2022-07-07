package v0.lib.net;

import haxe.Exception;
import haxe.Json;
import haxe.Timer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.net.URLRequestHeader;
import openfl.net.URLRequestMethod;
import openfl.net.URLVariables;
import v0.lib.Log;

class Method
{
	// Constants

	public static final GET = URLRequestMethod.GET;
	public static final POST = URLRequestMethod.POST;
	// In Flash available only for AIR
//	public static final PUT = URLRequestMethod.PUT;
//	public static final DELETE = URLRequestMethod.DELETE;
//	public static final HEAD = URLRequestMethod.HEAD;
//	public static final OPTIONS = URLRequestMethod.OPTIONS;
//	public static final PATCH = "PATCH";

	private static final ALL = [GET, POST, ];//PUT, DELETE, HEAD, OPTIONS, PATCH];

	// Methods

	public static function checkValid(method:String):Bool
	{
		return ALL.indexOf(method) != -1;
	}
}

class Format
{
	// Constants

	public static final BINARY = URLLoaderDataFormat.BINARY;
	public static final TEXT = URLLoaderDataFormat.TEXT;
	public static final JSON = "JSON";
	// Note: don't use VARIABLES and XML
}

/**
 * Request.
 * 
 * Better than URLLoader, because:
 *  - use only one class instead of URLRequest, URLLoader, URLVariables, URLRequestHeader,
 *  - more convenient input and output: Maps instead of URLVariables, URLRequestHeader; 
 *    callbacks receiving final data instead of event with raw data,
 *  - parsing data (JSON),
 *  - reusing instances by pooling (won't garbage collected),
 *  - logging (debug, errors), timing,
 *  - additional logic could be added (queueing, paralleling, periodical 
 *    resending on fail, checking internet connection, etc),
 *  - closing connection only if it's in progress.
 */
class Request
{
	// Static
	
//	// TODO use pool from static methods
//	private static var pool:Array<Request> = [];
//
//	public static function get(?url:String, ?params:Map<String, Dynamic>,
//						?callback:Dynamic -> Void, ?errorCallback:Dynamic -> Void,
//						?headers:Map<String, String>, ?format:String):Void
//	{
//		var request = new Request();
//		return request.get(url, params, callback, errorCallback, headers, format);
//	}
//
//	public static function post(?url:String, ?params:Map<String, Dynamic>,
//						 ?callback:Dynamic -> Void, ?errorCallback:Dynamic -> Void,
//						 ?headers:Map<String, String>, ?format:String):Void
//	{
//		var request = new Request();
//		return request.post(url, params, callback, errorCallback, headers, format);
//	}
	
	// Settings
	
	public static var defaultMethod = Method.GET;
	public static var defaultFormat = Format.TEXT;

	// State
	
	public var isInProgress(default, null):Bool = false;
	
	public var method(default, set):String;
	public function set_method(value:String):String
	{
		// Parameter urlRequest.method must be non-null
		if (value == null)
		{
			return method;
		}
		if (method != value)
		{
			method = value;
			value = value.toUpperCase();
			urlRequest.method = value;
		}
		return value;
	}
	
	public var baseURL(default, set):String;
	public function set_baseURL(value:String):String
	{
		if (baseURL != value)
		{
			baseURL = value;
			urlRequest.url = joinURL(value, url);
		}
		return value;
	}
	
	public var url(default, set):String;
	public function set_url(value:String):String
	{
		if (url != value)
		{
			url = value;
			urlRequest.url = joinURL(baseURL, value);
		}
		return value;
	}
	
	public var params(default, set):Map<String, Dynamic>;
	public function set_params(value:Map<String, Dynamic>):Map<String, Dynamic>
	{
		if (params != value)
		{
			params = value;
			var variables:URLVariables = null;
			if (value != null)
			{
				variables = new URLVariables();
				for (k => v in value)
				{
					Reflect.setField(variables, k, v);
				}
			}
			urlRequest.data = variables;
		}
		return value;
	}
	
	public var headers(default, set):Map<String, String>;
	public function set_headers(value:Map<String, String>):Map<String, String>
	{
		if (headers != value)
		{
			headers = value;
			var requestHeaders:Array<URLRequestHeader> = null;
			if (value != null)
			{
				requestHeaders = [];
				for (name => v in value)
				{
					requestHeaders.push(new URLRequestHeader(name, v));
				}
			}
			urlRequest.requestHeaders = requestHeaders;
		}
		return value;
	}
	
	public var callback:Dynamic->Void;
	public var errorCallback:Dynamic->Void;
	
	public var format(default, set):String;
	public function set_format(value:String):String
	{
		if (format != value)
		{
			format = value;
			if (value != null)
			{
				value = value.toUpperCase();
			}
			urlLoader.dataFormat = value == Format.BINARY ? 
				URLLoaderDataFormat.BINARY : URLLoaderDataFormat.TEXT;
		}
		return value;
	}
	
	private var urlRequest = new URLRequest();
	private var urlLoader = new URLLoader();
	private var isReady = false;
	
	// (No need to be cleared as they are set on send)
	private var sendTime:Float;
	private var expectingFormat:String;
	
	// Init
	
	public function new(?url:String, ?params:Map<String, Dynamic>,
						?callback:Dynamic->Void, ?errorCallback:Dynamic->Void,
						?headers:Map<String, String>, ?format:String)
	{
		//this.method = method;
		this.url = url;
		this.params = params;
		this.callback = callback;
		this.errorCallback = errorCallback;
		this.headers = headers;
		this.format = format;
	}
	
	public function dispose():Void
	{
		// Listeners
		isReady = false;
		urlLoader.removeEventListener(Event.COMPLETE, urlLoader_completeHandler);
		urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoader_ioErrorHandler);
		urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoader_securityErrorHandler);
		close();
		
		this.method = null;
		this.url = null;
		this.params = null;
		this.callback = null;
		this.errorCallback = null;
		this.headers = null;
		this.format = null;
	}

	// Methods

	public function send(?method:String, ?url:String, ?params:Map<String, Dynamic>,
						 ?callback:Dynamic -> Void, ?errorCallback:Dynamic -> Void,
						 ?headers:Map<String, String>, ?format:String):Void
	{
		close();
		// Update
		if (method != null) this.method = method;
		if (url != null) this.url = url;
		if (params != null) this.params = params;
		if (callback != null) this.callback = callback;
		if (errorCallback != null) this.errorCallback = errorCallback;
		if (headers != null) this.headers = headers;
		if (format != null) this.format = format;
		// Check
		if (this.method == null)
		{
			this.method = defaultMethod;
		}
		if (this.method == null || this.url == null || this.url == "")
		{
			Log.debug('Request can not be sent ${this.method} url: ${this.url}');
			return;
		}
	
		if (!isReady)
		{
			isReady = true;
			// Listeners
			urlLoader.addEventListener(Event.COMPLETE, urlLoader_completeHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_ioErrorHandler);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoader_securityErrorHandler);
		}

		// Save format as it can be changed between the request sent and the response received
		expectingFormat = this.format;
		// Send
		sendTime = Timer.stamp();
		isInProgress = true;
		Log.debug('Request send ${this.method} url: ${this.url} params: ${this.params}');
		urlLoader.load(urlRequest);
	}

	public function get(?url:String, ?params:Map<String, Dynamic>,
						?callback:Dynamic -> Void, ?errorCallback:Dynamic -> Void,
						?headers:Map<String, String>, ?format:String):Void
	{
		return send(Method.GET, url, params, callback, errorCallback, headers, format);
	}

	public function post(?url:String, ?params:Map<String, Dynamic>,
						 ?callback:Dynamic -> Void, ?errorCallback:Dynamic -> Void,
						 ?headers:Map<String, String>, ?format:String):Void
	{
		return send(Method.POST, url, params, callback, errorCallback, headers, format);
	}

	public function close():Void
	{
		if (isInProgress)
		{
			Log.debug('Request close $method url: $url params: $params');
			isInProgress = false;
			urlLoader.close();
		}
	}

	// Utility
	
	/**
	 * "http://domain/" + "/page" -> "http://domain//page"
	 * "http://domain" + "page" -> "http://domainpage"
	 */
	private function joinURL(baseURL:String, url:String):String
	{
		if (baseURL == null)
		{
			return url;
		}
		if (url == null)
		{
			return baseURL;
		}
		return baseURL + url;
	}
	
	private static function trim(data:Dynamic, maxLength=150):String
	{
		var str = Std.string(data);
		if (str.length > maxLength)
		{
			str = str.substring(0, maxLength - 3) + "...";
		}
		return str;
	}
	
	// Handlers

	private function urlLoader_completeHandler(event:Event):Void
	{
		isInProgress = false;
		var data:Dynamic = urlLoader.data;
		Log.debug('Request complete $method url: $url time: ${Timer.stamp() - sendTime} s ' +
			'data: ${trim(data)}');
		if (callback == null)
		{
			return;
		}
		if (expectingFormat == Format.JSON)
		{
			try
			{
				data = Json.parse(data);
			}
			catch (e:Exception)
			{
				Log.error('Error while parsing response for $method url: $url params: $params ' + 
					'data: ${trim(data)}');
			}
		}
		callback(data);
	}

	private function urlLoader_ioErrorHandler(event:IOErrorEvent):Void
	{
		isInProgress = false;
		Log.error('Request fail $method url: $url time: ${Timer.stamp() - sendTime} s $event');
		if (errorCallback != null)
		{
			errorCallback(event);
		}
		//checkInternetConnection();
	}

	private function urlLoader_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		isInProgress = false;
		Log.error('Request fail (security) $method url: $url time: ${Timer.stamp() - sendTime} s $event. ' + 
			'Please check crossdomain.xml on remote server');
		if (errorCallback != null)
		{
			errorCallback(event);
		}
	}
}
