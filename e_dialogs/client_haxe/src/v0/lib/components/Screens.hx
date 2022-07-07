package v0.lib.components;

import v0.lib.components.Component;

/**
 * Screens.
 * 
 * Container and root component for all screens.
 */
class Screens extends Component
{
	// Settings
	
	public var isReuseComponents = true;

	// State

	public static function getInstance():Screens
	{
		return IoC.getInstance().getSingleton(Screens);
	}
	
	public var currentScreen(default, null):Screen;
	private var currentScreenClass:Class<Screen>;
	private var screenByClassStringCache:Map<String, Screen> = new Map();

	// Init

	public function new()
	{
		super();

		// Throws exception if more than 1 instance
		IoC.getInstance().setSingleton(Screens, this);
	}

	override public function dispose():Void
	{
		for (s => screen in screenByClassStringCache)
		{
			screen.dispose();
		}
		screenByClassStringCache.clear();
		
		if (currentScreen != null)
		{
			currentScreen.dispose();
			currentScreen = null;
		}
		
		super.dispose();
	}

	// Methods

	public function open(screenClass:Class<Screen>):Screen
	{
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
			currentScreen = createComponent(screenClass);
		}
		addChild(currentScreen);
		return currentScreen;
	}
}
