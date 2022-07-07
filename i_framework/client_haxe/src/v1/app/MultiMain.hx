package v1.app;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v1.framework.ui.controls.KeyControl;
import v1.framework.MultiApplication;
import v1.framework.util.ArrayUtil;

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
