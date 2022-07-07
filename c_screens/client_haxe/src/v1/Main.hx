package v1;

import openfl.display.Sprite;
import v1.lib.Screen;
import v1.lib.Signal;

class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		Signal.test();
		
		var screen = new MenuScreen();
		// As not all libraries are preloaded and calling of Assets.loadLibrary() 
		// was chosen as common approach, listening to readySignal is required.
		// Listeners
		screen.readySignal.add(screen_readySignalHandler);
	}

	// Handlers

	private function screen_readySignalHandler(target:Screen):Void
	{
		// Listeners
		target.readySignal.remove(screen_readySignalHandler);
		
		addChild(target.skin);
	}
}
