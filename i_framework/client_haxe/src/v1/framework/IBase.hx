package v1.framework;

/**
 * IBase.
 * 
 * Application can't extend Base because it should extend Sprite, 
 * so an interface is needed.
 * 
 * Extend Base wherever you need ioc inside.
 */
interface IBase
{
	// Settings

	// State
	
	private var ioc(default, set):IoC;

	// Methods
	
	public function dispose():Void;

}
