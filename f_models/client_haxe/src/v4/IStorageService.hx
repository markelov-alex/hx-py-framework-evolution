package v4;

import v0.lib.Signal;

/**
 * IStorageService.
 * 
 */
interface IStorageService
{
	// Settings

	// State
	
	// Signals

	public var loadSignal(default, null):Signal<Dynamic>;
	public var stateChangeSignal(default, null):Signal<Dynamic>;
	public var itemChangeSignal(default, null):Signal2<Dynamic, Dynamic>;

	// Methods

	public function load():Void;
	public function setState(value:Dynamic):Void;
	public function changeItem(index:Dynamic, value:Dynamic):Void;
}
