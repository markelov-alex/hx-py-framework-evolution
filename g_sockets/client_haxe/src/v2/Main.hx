package v2;

import openfl.display.Sprite;
import v0.lib.AudioManager;
import v0.lib.components.Screens;
import v0.lib.IoC;
import v0.lib.LangManager;
import v1.coloring.ColoringModel;
import v1.coloring.Picture;
import v1.dresser.Dresser;
import v1.menu.MenuScreen;
import v2.coloring.IColoringProtocol;
import v2.dresser.IDresserProtocol;
import v2.lib.net.IProtocol;
import v2.lib.net.Protocol;

/**
 * Main.
 * 
 * Changes:
 *  - use protocol controllers instead of models.
 */
class Main extends Sprite
{
	// Settings
	
	private var host = "localhost";
	private var port = 5555;
	
	// State
	
	// Init
	
	public function new()
	{
		super();

		// First of all register all class substitution
		setUp();

		var ioc = IoC.getInstance();
		ioc.load();
		LangManager.getInstance().load();
		AudioManager.getInstance().load();
		
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);

 		// Use Protocol, not IProtocol, because we can (for testing)
		var protocol:IProtocol = ioc.getSingleton(Protocol);
		protocol.connect(host, port);
	}

	private function setUp():Void
	{
		// Note: Add IDresserProtocol and IColoringProtocol for next versions
		var ioc = IoC.getInstance();
		ioc.register(Dresser, v2.dresser.Dresser);
		ioc.register(IDresserProtocol, v2.dresser.DresserProtocol);
		ioc.register(ColoringModel, v2.coloring.ColoringModel);
		ioc.register(IColoringModel, v2.coloring.ColoringModel);
		ioc.register(IColoringProtocol, v2.coloring.ColoringProtocol);
		ioc.register(Picture, v2.coloring.Picture);
	}
}
