package v3.lib;

import v3.lib.Component;

/**
 * Screens.
 * 
 * Container and root component for all screens.
 * 
 * Changes:
 *  - reuse screen components (if isReuseComponents).
 */
class Screens extends Component
{
	// Settings
	
	public var isReuseComponents = true;

	// State
	
	public var currentScreen(default, null):Screen;
	private var currentScreenClass:Class<Screen>;
	private var screenByClassStringCache:Map<String, Screen> = new Map();

	// Init

//	public function new()
//	{
//		super();
//	}

	override public function dispose():Void
	{
		for (s => screen in screenByClassStringCache)
		{
			screen.dispose();
		}
		screenByClassStringCache.clear();
		super.dispose();
	}

	// Methods

	//public function open(screenClass:Class<Screen>, args:Array<Dynamic>=[]):Screen
	public function open(screenClass:Class<Screen>):Screen
	{
		var args = [];//
		if (screenClass == null || currentScreenClass == screenClass)
		{
			return null;
		}
		
		// Hide previous
		if (currentScreen != null)
		{
			if (isReuseComponents)
			{
				removeChild(currentScreen);
				screenByClassStringCache[Type.getClassName(currentScreenClass)] = currentScreen;
			}
			else
			{
				currentScreen.dispose();
			}
		}
		
		// Show new
		currentScreenClass = screenClass;
		if (isReuseComponents)
		{
			// Reuse previous of same type
			var key = Type.getClassName(currentScreenClass);
			currentScreen = screenByClassStringCache[key];
			screenByClassStringCache.remove(key);
		}
		if (!isReuseComponents || currentScreen == null)
		{
			// Create new
			currentScreen = Type.createInstance(screenClass, args);
		}
		addChild(currentScreen);
		return currentScreen;
	}
}
