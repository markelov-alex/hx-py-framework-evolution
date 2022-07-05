package v1;

import openfl.utils.Assets;
import openfl.display.Sprite;

class Main extends Sprite
{
	// Init

	public function new()
	{
		super();

		// If preload="true"
		var mc = new AssetDresserScreen();
		addChild(mc);
		// Same result:
		var mc2 = Assets.getMovieClip("dresser:AssetDresserScreen");
		mc2.x = 100;
		addChild(mc2);

		// If preload="false"
		Assets.loadLibrary("dresser").onComplete(function(library)
		{
			var mc3 = new AssetDresserScreen();
			mc3.x = 200;
			addChild(mc3);
		});
	}
}
