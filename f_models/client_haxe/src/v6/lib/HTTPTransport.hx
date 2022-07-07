package v6.lib;

import v0.lib.Signal;
import v5.lib.Request;

/**
 * HTTPTransport.
 * 
 */
class HTTPTransport implements ITransport
{
	// Settings
	
	public var url:String;

	// State

	// Signals
	
	public var receiveDataSignal(default, null) = new Signal<Dynamic>();
	public var errorSignal(default, null) = new Signal<Dynamic>();

	// Init

	//public function new()
	//{
	//    super();
	//}

	// Methods

	/**
	 * Note: data:Dynamic only needed to define method for RESTful server API. 
	 * Later we can refuse RESTful API in favor of command in plainData unifying 
	 * it with Sockets, so "method" and hence "data" paramater won't be needed 
	 * and will be removed.
	 */
	public function send(plainData:String, ?data:Dynamic):Void
	{
		var method = data != null ? data._method : null;
		var params = {data: plainData};
		new Request().send(method, url, params, function(data:Dynamic):Void {
			// Dispatch
			receiveDataSignal.dispatch(data);
		}, function(error:Dynamic):Void {
			// Dispatch
			errorSignal.dispatch(error);
		});
	}
}
