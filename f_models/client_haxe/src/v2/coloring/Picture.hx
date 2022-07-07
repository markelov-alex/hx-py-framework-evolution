package v2.coloring;

import openfl.events.MouseEvent;

/**
 * Picture.
 * 
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
	
	// Handlers

	override private function pictureItem_clickSignalHandler(event:MouseEvent):Void
	{
		super.pictureItem_clickSignalHandler(event);
		
		var model:ColoringModel = Std.downcast(this.model, ColoringModel);
		model.save();
	}
}
