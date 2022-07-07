package v2;

import v2.lib.Application;

/**
 * Main.
 * 
 * MultiApplication as the Loader. It doesn't load an app, as it's possible 
 * only on Flash platform, but creates other applications inside it.
 * 
 * Changes:
 *  - remove all static singleton methods, get all singletons only via IoC 
 *  injected to each newly created instance,
 *  - as components creation needs IoC, all subcomponent creation moves from 
 *  constructor to new init(), called from ioc setter.
 *  As these changes affect all base and core classes, only interfaces and 
 *  util classes left untouched,
 *  - Component, Application and, optionally, others implement init()-dispose() 
 *  concept which make them reuseable (previously initialization was in 
 *  constructor, which we can't call again for same instance). Now you need 
 *  only set ioc to activate (initialize) such instance (init() and dispoe() are 
 *  called in ioc setter),
 *  - as components can be initialized and disposed multiple times, i.e. all 
 *  subcomponents not tied with their parents forever, so all add listeners should 
 *  be removed. The simplest way to do so is to dispose all internal signals in 
 *  component's dispose() method. From now on it is the rule.
 *  - todo rename names like "audioManager" to simplier one like "audio".
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
