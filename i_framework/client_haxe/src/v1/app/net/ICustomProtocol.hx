package v1.app.net;

import v1.framework.net.IProtocol;
import v1.framework.util.Signal;

/**
 * ICustomProtocol.
 * 
 */
interface ICustomProtocol extends IProtocol
{
	// Signals

	public var setDataSignal(default, null):Signal2<String, Dynamic>;
	public var updateDataSignal(default, null):Signal2<String, Dynamic>;
	public var gotoSignal(default, null):Signal<String>;
	
	// Methods

	public function load(name:String):Void;
	public function update(name:String, data:Dynamic):Void;
	public function goto(name:String):Void;
	
}
