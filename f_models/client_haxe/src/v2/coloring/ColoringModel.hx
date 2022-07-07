package v2.coloring;

import openfl.net.SharedObject;
import v0.lib.Log;

/**
 * ColoringModel.
 * 
 */
class ColoringModel extends v1.coloring.ColoringModel
{
	// Settings

	// State
	
	private var shared = SharedObject.getLocal("coloring");

	override public function set_pictureIndex(value:Int):Int
	{
		shared.data.pictureIndex = value;
		shared.flush();
		return super.set_pictureIndex(value);
	}

	// It's better to use save() method, as currentPictureState also changes on 
	// pictureIndex change, but there saving should not happen!
	//override public function set_currentPictureState(value:Array<Int>):Array<Int>
	//{
	//	// Change pictureStates
	//	var result = super.set_currentPictureState(value);
	//	save();
	//	return result;
	//}

	override public function set_colorIndex(value:Int):Int
	{
		shared.data.colorIndex = value;
		shared.flush();
		return super.set_colorIndex(value);
	}

	// Init

	public function new()
	{
		super();

		Log.info('$this v2');
		state = shared.data;
	}

	// Methods

	public function save():Void
	{
		// Save pictureStates
		shared.data.pictureStates = pictureStates;
		shared.flush();
	}
}

