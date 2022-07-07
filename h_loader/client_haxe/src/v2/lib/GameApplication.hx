package v2.lib;

import v0.lib.net.IProtocol;
import v2.lib.components.Screens;

/**
 * GameApplication.
 * 
 * Changes:
 *  - move managers initialization to Application as managers are needed 
 *  in any kind of applications,
 *  - now, when each Application has its own IoC, we can create Screens as singleton.
 */
class GameApplication extends Application
{
	// Settings
	
	// State

	// Init

//	public function new()
//	{
//		super();
//	}

	override private function init():Void
	{
		super.init();

		// Initialize view
		screens = ioc.getSingleton(Screens);
		screens.isReuseComponents = false;
		screens.skin = this;

		// Initialize logic
		protocol = ioc.getSingleton(IProtocol);
	}

	override public function dispose():Void
	{
		if (screens != null)
		{
			screens.dispose();
		}
		if (protocol != null)
		{
			protocol.dispose();
		}
		
		super.dispose();
	}

	override private function start():Void
	{
		super.start();
		
		// Start up the app (view)
		screens.open(startScreenClass);

		// Connect (logic)
		if (host != null)
		{
			protocol.connect(host, port);
		}
	}

	// Methods
	
}
