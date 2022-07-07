package v1.lib.components;

import openfl.display.DisplayObject;
import v0.lib.components.Resizer.StageResizer;

/**
 * StageResizer2.
 * 
 */
class StageResizer2 extends StageResizer
{
	// Settings

	// State

	override private function set_sizeSource(value:DisplayObject):DisplayObject
	{
		application = Std.downcast(value, Application);
		return super.set_sizeSource(value);
	}
	private var application:Application;

	override private function get_sourceWidth():Float
	{
		return application != null ? application.stageWidth : super.get_sourceWidth();
}

	override private function get_sourceHeight():Float
	{
		return application != null ? application.stageHeight : super.get_sourceHeight();
	}

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		sizeSource = findSkinParentOfType(skin, Application);
	}

	private function findSkinParentOfType(skin:DisplayObject, type:Class<Dynamic>):DisplayObject
	{
		if (skin == null || skin.parent == null)// || skin == skin.parent)
		{
			return null;
		}
		var parent = skin.parent;
		if (Std.isOfType(parent, type))
		{
			return parent;
		}
		return findSkinParentOfType(parent, type);
	}
}
