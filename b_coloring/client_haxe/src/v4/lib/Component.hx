package v4.lib;

/**
 * Component.
 * 
 * Changes:
 * - Add parent-children for:
 * 	 - automatically clearing up the whole component hierarchy by unassigning root skin,
 * 	 - implementing radio groups in RadioButton.
 */
class Component extends v2.lib.Component
{
	// Settings

	// State

	public var parent(default, null):v2.lib.Component;
	public var children(default, null):Array<v2.lib.Component> = [];

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function unassignSkin():Void
	{
		for (child in children.copy())
		{
			child.skin = null;
			removeChild(child);
		}
		
		super.unassignSkin();
	}

	public function addChild(child:Component):Component
	{
		if (child.parent == this)
		{
			return child;
		}

		// Remove from previous
		if (child.parent != null)
		{
			child.parent.removeChild(child);
		}

		// Add
		child.parent = this;
		children.push(child);
	}

	public function removeChild(child:Component):Component
	{
		if (child.parent != this)
		{
			return null;
		}
		child.parent = null;
		children.remove(child);
	}
}
