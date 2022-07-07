package v2.lib.components;

/**
 * Component.
 * 
 * Changes:
 *  - on disable all children are also disabled.
 */
class Component extends v0.lib.components.Component
{
	// Settings

	// State

	override public function get_isEnabled():Bool
	{
		return isEnabled && isParentEnabled;
	}

	/**
	 * Disabling all children on isEnabled = false.
	 */
	@:isVar public var isParentEnabled(default, set):Bool = true;
	public function set_isParentEnabled(value:Bool):Bool
	{
		if (isParentEnabled != value)
		{
			isParentEnabled = value;

			// Set isParentEnabled recursively
			refreshEnabled();
		}
		return value;
	}
	
	/**
	 * Another way to implement isParentEnabled, but much more expensive: 
	 * too many getters should be called to know only one value. 
	 * As getters called more often than setters, we've chosen another way 
	 * (see above). 
	 */
//	private var isParentEnabled(get, null):Bool;
//	private function get_isParentEnabled():Bool
//	{
//		return parent.isEnabled;
//	}

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function refreshEnabled():Void
	{
		super.refreshEnabled();

		// Set isParentEnabled recursively
		var isEnabled = this.isEnabled;
		if (isParentEnabled || !isEnabled)
		{
			for (child0 in children)
			{
				var child:Component = Std.downcast(child0, Component);
				if (child != null)
				{
					child.isParentEnabled = isEnabled;
				}
			}
		}
	}	
}
