package v1.lib.components;

import haxe.Exception;
import v1.lib.components.Resizer.StageResizer;
import v1.lib.components.Component;

/**
 * Screens.
 * 
 * Container and root component for all screens.
 * 
 * Changes:
 *  - make singleton as we may need to open any screen anywhere, 
 *    and at the same time can not make this static, 
 *  - add StageResizer.
 */
class Screens extends Component
{
	// Settings
	
	public var isReuseComponents = true;

	// State

	private static var instance:Screens;
	public static function getInstance():Screens
	{
		if (instance == null)
		{
			instance = new Screens();
		}
		return instance;
	}
	
	public var currentScreen(default, null):Screen;
	private var currentScreenClass:Class<Screen>;
	private var screenByClassStringCache:Map<String, Screen> = new Map();
	
	// TODO move to Screen to enable separate resizing strategy for each screen
	private var resizer:Resizer;

	// Init

	public function new()
	{
		super();

		if (instance != null)
		{
			throw new Exception("Singleton class can have only one instance!");
		}
		else
		{
			// Should be set only once
			instance = this;
		}
		
		resizer = new StageResizer();
		addChild(resizer);
	}

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
