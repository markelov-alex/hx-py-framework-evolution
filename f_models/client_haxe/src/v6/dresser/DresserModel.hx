package v6.dresser;

import v0.lib.IoC;

/**
 * DresserModel.
 * 
 */
class DresserModel extends v4.dresser.DresserModel
{
	// Settings

	// State
	
	// Init

	override private function init():Void
	{
		service = IoC.getInstance().create(DresserService);
	}

	// Methods
}
