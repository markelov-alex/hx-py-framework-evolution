package v6.lib;

import v0.lib.Signal;

/**
 * ITransport.
 * 
 */
interface ITransport
{
	// Settings

	public var url:String;
	
	// State

	// Signals
	
	public var receiveDataSignal(default, null):Signal<Dynamic>;
	public var errorSignal(default, null):Signal<Dynamic>;

	// Methods

	/**
	 * data - source data
	 * plainData - stringified data
	 */
	public function send(plainData:String, ?data:Dynamic):Void;
}
