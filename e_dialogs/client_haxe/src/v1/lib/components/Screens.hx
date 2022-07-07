package v1.lib.components;

import v0.lib.Log;
import v0.lib.components.Screen;
import v0.lib.components.Component;

/**
 * Screens.
 * 
 * Container and root component for all screens and dialogs.
 */
class Screens extends v0.lib.components.Screens
{
	// Settings
	
	// State
	
	private var localDialogs:Array<Component> = [];
	private var globalDialogs:Array<Component> = [];
	private var pool:Map<String, Component> = new Map();

	// Init

	public function new()
	{
		super();

		// todo remove
		screenByClassStringCache = null;
	}

	override public function dispose():Void
	{
		for (instance in pool)
		{
			instance.dispose();
		}
		pool.clear();
		
		for (dialog in localDialogs)
		{
			dialog.dispose();
		}
		for (dialog in globalDialogs)
		{
			dialog.dispose();
		}
		localDialogs.resize(0);
		globalDialogs.resize(0);
		
		super.dispose();
	}

	// Methods

	override public function open(type:Class<Screen>):Screen
	{
		if (currentScreenClass == type)
		{
			return currentScreen;
		}
		
		// Close previous
		for (dialog in localDialogs)
		{
			dialog.dispose();
		}
		localDialogs.resize(0);
		close(currentScreen);
		
		// Open new
		currentScreenClass = type;
		currentScreen = Std.downcast(_open(cast type), Screen);
		//currentScreen = _open(type, true);
		
		// Move new screen to the bottom, under all global dialogs (and other elements if any)
		if (currentScreen != null && currentScreen.skin != null)
		{
			currentScreen.skin.parent.addChildAt(currentScreen.skin, 0);
		}
		return currentScreen;
	}

	// Any component with assetName set can be showed as a dialog, including screens
	public function openDialog(type:Class<Component>, ?global:Bool):Component
	{
		var dialog = _open(type);
		if (dialog != null)
		{
			if (global)
			{
				globalDialogs.push(dialog);
			}
			else
			{
				localDialogs.push(dialog);
			}
		}
		return dialog;
	}

	private function _open(type:Class<Component>):Component
	{
		if (type == null)
		{
			return null;
		}
		
		// Get or create
		var instance:Component = null;
		if (isReuseComponents)
		{
			// Reuse previous of same type
			var key = Type.getClassName(type);
			instance = pool[key];
			pool.remove(key);
		}
		if (instance == null)
		{
			// Create new
			instance = createComponent(type);
		}
		if (instance.assetName == null)
		{
			Log.warn('For screens and dialogs ($instance) assetName shouldn\'t be null, ' + 
				'as it would be nothing to display!');
		}
		
		// Add
		addChild(instance);
		return instance;
	}

	// For both screens and dialogs
	public function close(instance:Component):Void
	{
		if (instance == null)
		{
			return;
		}
		
		// Remove
		var isRemoved = false;
		if (instance == currentScreen)
		{
			currentScreen = null;
			currentScreenClass = null;
			isRemoved = true;
		}
		if (localDialogs.contains(instance))
		{
			localDialogs.remove(instance);
			isRemoved = true;
		}
		if (globalDialogs.contains(instance))
		{
			globalDialogs.remove(instance);
			isRemoved = true;
		}
		if (!isRemoved)
		{
			return;
		}

		// Put to pool for reusing
		if (isReuseComponents)
		{
			instance.parent.removeChild(instance);
			var className = Type.getClassName(Type.getClass(instance));
			if (!pool.exists(className))
			{
				pool[className] = instance;
				return;
			}
		}
		// Dispose
		instance.dispose();
	}
}
