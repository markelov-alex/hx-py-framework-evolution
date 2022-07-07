package v2.lib.components;

import openfl.display.DisplayObject;
import v1.lib.components.Resizer.AlignH;
import v1.lib.components.Resizer.AlignV;
import v1.lib.components.Resizer.ResizeMode;

/**
 * StageResizer.
 * 
 */
class StageResizer extends v1.lib.components.Resizer.StageResizer
{
	// Settings

	public var stretchBackgroundPath = "background";

	// State

	private var stretchBackground:DisplayObject;

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		// Before resize() called in super.assignSkin()
		stretchBackground = resolveSkinPath(stretchBackgroundPath);

		super.assignSkin();
	}

	override private function unassignSkin():Void
	{
		stretchBackground = null;

		super.unassignSkin();
	}

	override public function resize():Void
	{
		super.resize();

		// Stretch background to stage size
		if (stretchBackground != null && resizeMode == ResizeMode.FIT_MIN)
		{
			stretchBackground.width = sourceWidth / skin.scaleX;
			stretchBackground.height = sourceHeight / skin.scaleY;
		
			// Suppose, that background's center is in the same place (corner) as for the skin itself 
			switch alignH
			{
				case AlignH.LEFT:
					stretchBackground.x = -skin.x / skin.scaleX;
				case AlignH.RIGHT:
					stretchBackground.x = (sourceWidth - skin.x) / skin.scaleX;
				case AlignH.CENTER:
					stretchBackground.x = 0;
			}
			switch alignV
			{
				case AlignV.TOP:
					stretchBackground.y = -skin.y / skin.scaleY;
				case AlignV.BOTTOM:
					stretchBackground.y = (sourceHeight - skin.y) / skin.scaleY;
				case AlignV.CENTER:
					stretchBackground.y = 0;
			}
			
			// For test
			//stretchBackground.width -= 6;
			//stretchBackground.height -= 6;
			//stretchBackground.x += 3;
			//stretchBackground.y += 3;
		}
	}
}
