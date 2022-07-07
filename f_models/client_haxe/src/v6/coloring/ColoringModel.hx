package v6.coloring;

import v0.lib.IoC;

/**
 * ColoringModel.
 * 
 */
class ColoringModel extends v4.coloring.ColoringModel
{
	// Settings
	
	// State

	// Init

	override private function init():Void
	{
		service = IoC.getInstance().create(ColoringService);
	}

	// Methods
}

