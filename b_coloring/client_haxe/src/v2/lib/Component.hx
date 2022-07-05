package v2.lib;

import openfl.display.SimpleButton;
import openfl.display.InteractiveObject;
import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.DisplayObject;

/**
 * Component.
 * 
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
	}
}
