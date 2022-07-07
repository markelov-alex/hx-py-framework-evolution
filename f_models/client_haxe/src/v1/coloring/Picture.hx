package v1.coloring;

import openfl.events.MouseEvent;
import v1.coloring.ColoringModel;

/**
 * Picture.
 * 
 */
class Picture extends v0.coloring.Picture
{
	// Settings

	// State

	private var model:ColoringModel;

	// Init

	public function new()
	{
		super();

		model = ioc.getSingleton(ColoringModel);
		// Listeners
		model.currentPictureStateChangeSignal.add(model_currentPictureStateChangeSignalHandler);

		// TODO replace 15 code lines with only 1 (property=name by default):
		// Only from model to component. If you need to change model, do it explicitly.
		//public function bind(name:String, model:Model=null, property:String=null, signal:Dynamic=null):Void 
		//bind("pictureState", model, "currentPictureState");
		// 1. set value from model,
		// 2. listen signal for value change,
		// 3. add unlisten function to a list which should be processed in dispose().
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Apply
		pictureState = model.currentPictureState;
	}
	
	// Handlers

	private function model_currentPictureStateChangeSignalHandler(value:Array<Int>):Void
	{
		// Refresh skin
		pictureState = model.currentPictureState;
	}

	override private function pictureItem_clickSignalHandler(event:MouseEvent):Void
	{
		super.pictureItem_clickSignalHandler(event);

		// Refresh model
		model.currentPictureState = pictureState;
	}
}
