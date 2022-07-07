package v8;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import v7.lib.net.IProtocol;
import v7.lib.util.Log;
import v8.net.CustomProtocol;

/**
 * Main.
 * 
 * Changes:
 *  - add message buffering to always send message encoded in old protocol before 
 *  version message, to demonstrate switch parser bug, when parser was changed 
 *  on only one side (client or server), and message still coming encoded 
 *  in previous protocol from the other side. So, if you see some 
 *  "Error #1132: Invalid JSON parse input" in your logs, that's what we needed.
 *  In v9 this bug is fixed by splitting inside MultiParser on 
 *  inputParser and outputParser.
 */
class Main extends v7.Main
{
	// Settings

	
	// State
	
	// Init
	
	override private function configureApp():Void
	{
		super.configureApp();
//		ioc.register(IProtocol, CustomProtocol);
		ioc.register(v7.net.CustomProtocol, CustomProtocol);
	}

	// Handlers

	override private function stage_keyUpHandler(event:KeyboardEvent):Void
	{
		super.stage_keyUpHandler(event);
		
		// (To disable client buffer (set 0) for testing server buffer)
		var isPlus = event.keyCode == Keyboard.NUMPAD_ADD;
		if (isPlus || event.keyCode == Keyboard.NUMPAD_SUBTRACT)
		{
			var protocol:IProtocol = ioc.getSingleton(IProtocol);
			if (Reflect.hasField(protocol, "minPlainDataBufferLength"))
			{
				var val = Reflect.field(protocol, "minPlainDataBufferLength");
				val += isPlus ? 1 : -1;
				Reflect.setField(protocol, "minPlainDataBufferLength", val > 0 ? val : 0);
				Log.debug('Change minPlainDataBufferLength: $val');
			}
		}
	}
}
