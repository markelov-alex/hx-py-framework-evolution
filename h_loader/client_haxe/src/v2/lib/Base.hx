package v2.lib;

/**
 * Base.
 * 
 * After instantiation ioc property should be set for initialization.
 * To destroy instance and clear up all the references for Garbage collector, 
 * call dispose() or set ioc=null.
 */
class Base implements IBase
{
	// Settings

	// State

	private var ioc(default, set):IoC;
	private function set_ioc(value:IoC):IoC
	{
		var ioc = this.ioc;
		if (ioc != value)
		{
			if (ioc != null)
			{
				// (To prevent calling set_ioc() again on ioc=null in dispose())
				this.ioc = null;
				// Dispose previous state
				dispose();
			}
			// Set
			this.ioc = ioc = value;
			if (ioc != null)
			{
				// Initialize
				init();
			}
		}
		return value;
	}

	// Init

	// Override to change defaults and other settings which should be set only once
	public function new()
	{
	}

	// Override for initialization (using IoC)
	private function init():Void
	{
	}

	// Override to revert changes of init and clear up the memory
	public function dispose():Void
	{
		ioc = null;
	}

	// Methods

}
