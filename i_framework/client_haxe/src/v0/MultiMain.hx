package v0;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v0.lib.util.ArrayUtil;
import v0.lib.components.KeyControl;
import v0.lib.MultiApplication;

/**
 * Main.
 * 
 * Press numpad numbers to change loaded applications count.
 */
class MultiMain extends MultiApplication
{
	// Settings

	// State
	
	private var keyControl:KeyControl;

	// Init

//	public function new()
//	{
//		super();
//	}

	override private function init():Void
	{
		ArrayUtil.test();
		
		defaultAppClass = AppMain;
		
		super.init();
		
		keyControl = ioc.create(KeyControl);
		keyControl.skin = this;
		// Listeners
		keyControl.keyUpSignal.add(keyControl_keyUpSignalHandler);
	}

	override public function dispose():Void
	{
		// Listeners
		keyControl.keyUpSignal.remove(keyControl_keyUpSignalHandler);
		keyControl.dispose();
		
		super.dispose();
	}

	// Methods
	
	// Handlers

	private function keyControl_keyUpSignalHandler(event:KeyboardEvent):Void
	{
		if (event.keyCode >= Keyboard.NUMPAD_0 && event.keyCode <= Keyboard.NUMPAD_9)
		{
			appCount = event.keyCode - Keyboard.NUMPAD_0;
		}
	}
}
