package v3.coloring;

import openfl.events.MouseEvent;

/**
 * Picture.
 * 
 * Can not extend v2 Picture as ColoringModel also doesn't extend v2 ColoringModel. 
 */
class Picture extends v1.coloring.Picture
{
	// Settings

	// State

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		var model:ColoringModel = Std.downcast(this.model, ColoringModel);
		model.load();
	}
	
	// Handlers

	override private function pictureItem_clickSignalHandler(event:MouseEvent):Void
	{
		super.pictureItem_clickSignalHandler(event);
		
		var model:ColoringModel = Std.downcast(this.model, ColoringModel);
		model.save();
	}
}
