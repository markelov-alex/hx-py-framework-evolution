package v2.lib;

import v1.lib.Component;

/**
 * Screens.
 * 
 * Container and root component for all screens.
 */
class Screens extends Component
{
	// Settings

	// State
	
	public var currentScreen(default, null):Screen;
	private var currentScreenClass:Class<Screen>;

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

//	public function open(screenClass:Class<Screen>, args:Array<Dynamic>=[]):Screen
	public function open(screenClass:Class<Screen>):Screen
	{
		var args = [];
		if (screenClass == null || currentScreenClass == screenClass)
		{
			return null;
		}
		
		// Dispose previous
		if (currentScreen != null)
		{
			removeChild(currentScreen);
		}
		
		// Create new screen
		currentScreenClass = screenClass;
		currentScreen = Type.createInstance(screenClass, args);
		addChild(currentScreen);
		return currentScreen;
	}
}
