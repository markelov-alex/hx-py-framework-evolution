package v2.lib.components;

import v1.lib.components.Screens in Screens1;

/**
 * Screens.
 * 
 */
class Screens extends Screens1
{
	// Settings

	// State
	
	public static function getInstance():Screens1
	{
		if (Screens1.instance == null)
		{
			Screens1.instance = new Screens();
		}
		return Screens1.instance;
	}
	
	// Init

	public function new()
	{
		super();

		// Disable global resizer
		removeChild(resizer);
	}

	// Methods

}
