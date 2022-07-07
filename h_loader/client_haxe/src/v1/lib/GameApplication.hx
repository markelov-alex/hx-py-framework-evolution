package v1.lib;

import v0.lib.AudioManager;
import v0.lib.components.Screens;
import v0.lib.LangManager;
import v0.lib.net.IProtocol;

/**
 * GameApplication.
 * 
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

	// Methods

	override private function init():Void
	{
		super.init();

		// Initialize IoC
		ioc.load();

		// Initialize managers
		var langManager = ioc.getSingleton(LangManager);
		var audioManager = ioc.getSingleton(AudioManager);
		langManager.load();
		audioManager.load();

		// Initialize view
		screens = ioc.create(Screens);
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
			protocol = ioc.getSingleton(IProtocol);
			protocol.connect(host, port);
		}
	}
}
