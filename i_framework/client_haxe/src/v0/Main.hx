package v0;

import v0.lib.Application;

/**
 * Main.
 * 
 * MultiApplication as the Loader. It doesn't load an app, as it's possible 
 * only on Flash platform, but creates other applications inside it.
 * 
 * todo rename names like "audioManager" to simplier one like "audio".
 */
class Main extends MultiMain
{
	// Settings

	// State

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	// Recursive loading demonstration
	override private function createApp(index:Int, ?appClass:Class<Application>, ?args:Array<Dynamic>):Application
	{
		// Make 4th window display another MultiApplication
		if (appClass == null && index == 3)
		{
			appClass = MultiMain;
		}
		return super.createApp(index, appClass, args);
	}
}
