package v5.lib;

import openfl.display.SimpleButton;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.DisplayObject;

/**
 * Component.
 * 
 * Changes:
 * - Add resolveSkinPath(somePath) to use it instead of:
 * 	if (container != null) container.getChildByName(someName) else null;
 * - Move findChildrenByNamePrefix() from Coloring as resolveSkinPathPrefix().
 */
class Component
{
	// Settings

	// State

	/**
	 * "Template method" for parsing skin, adding listeners, etc, 
	 * and clearing it up.
	 */
	public var skin(default, set):DisplayObject;
	public function set_skin(value:DisplayObject):DisplayObject
	{
		if (skin == value)
		{
			// Same value
			return value;
		}
		if (skin != null)
		{
			unassignSkin();
		}
		// Set
		skin = value;
		interactiveObject = Std.downcast(value, InteractiveObject);
		simpleButton = Std.downcast(value, SimpleButton);
		container = Std.downcast(value, DisplayObjectContainer);
		sprite = Std.downcast(value, Sprite);
		mc = Std.downcast(value, MovieClip);
		if (skin != null)
		{
			assignSkin();
		}
		return value;
	}
	public var interactiveObject(default, null):InteractiveObject;
	public var simpleButton(default, null):SimpleButton;
	public var container(default, null):DisplayObjectContainer;
	public var sprite(default, null):Sprite;
	public var mc(default, null):MovieClip;

	public var parent(default, null):Component;
	public var children(default, null):Array<Component> = [];

	// Init

	public function new()
	{
	}

	// Methods

	/**
	 * Entry point to a component. Skin is guaranteed to be not null.
	 */
	// Override
	private function assignSkin():Void
	{
	}

	/**
	 * Exit point from a component. 
	 * Clear up all links to a skin before it's removed.
	 */
	// Override
	private function unassignSkin():Void
	{
		// Clear up all children
		for (child in children.copy())
		{
			child.skin = null;
			removeChild(child);
		}
	}

	public function addChild(child:Component):Component
	{
		if (child == null || child.parent == this)
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
		return child;
	}

	public function removeChild(child:Component):Component
	{
		if (child == null || child.parent != this)
		{
			return null;
		}
		child.parent = null;
		children.remove(child);
		return child;
	}

	/**
	 * Aims:
	 * 1. Replace:
 	 * 		some = if (container != null) container.getChildByName(someName) else null;
 	 * 	with:	
 	 * 		some = resolveSkinPath(somePath);
 	 * 2. Get nested object by name chain like this: "parent.buttons.menuButton1".	
	 */
	private function resolveSkinPath(path:String):DisplayObject
	{
		if (container == null || path == null || path == "")
		{
			return container;
		}
		var source = container;
		var result:DisplayObject = null;
		var pathParts:Array<String> = path.split(".");
		var count = pathParts.length;
		for (i in 0...count)
		{
			if (source == null)
			{
				return null;
			}
			var name = pathParts[i];
			result = if (name == "parent") source.parent else source.getChildByName(name);
			if (result == null)
			{
				return null;
			}
			if (i < count - 1)
			{
				source = Std.downcast(result, DisplayObjectContainer);
			}
		}
		return result;
	}

	/**
	 * Get all display objects with names beginning with pathPrefix.
	 */
	private function resolveSkinPathPrefix(pathPrefix:String, maxGapCount=5):Array<DisplayObject>
	{
		var items = [];
		var i = 0;
		var absent = 0;
		while (true)
		{
			var item = resolveSkinPath(pathPrefix + i);
			if (item == null)
			{
				// Skip gaps in name (e.g. if "color1", "color2", "color5")
				absent++;
				if (absent >= maxGapCount)
				{
					// No more children
					break;
				}
			}
			else
			{
				// Another child is found
				absent = 0;
				items.push(item);
			}
			i++;
		}
		return items;
	}
}
