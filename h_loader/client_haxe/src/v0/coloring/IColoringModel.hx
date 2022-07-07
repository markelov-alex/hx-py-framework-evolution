package v0.coloring;

import v0.coloring.ColoringModel.ColoringState;
import v0.lib.util.Signal;

/**
 * IColoringModel.
 * 
 */
interface IColoringModel
{
	// Settings

	public var defaultColor:Int;
	public var colors:Array<Int>;
	public var maxPictureIndex:Int;

	// State

	public var state(get, set):ColoringState;
	public var pictureStates(default, set):Array<Array<Int>>;
	public var pictureIndex(default, set):Int;
	public var currentPictureState(default, set):Array<Int>;
	public var colorIndex(default, set):Int;
	public var color(default, null):Int;

	// Signals

	public var pictureChangeSignal(default, null):Signal<Int>;
	public var currentPictureStateChangeSignal(default, null):Signal<Array<Int>>;
	public var colorChangeSignal(default, null):Signal<Int>;
}
