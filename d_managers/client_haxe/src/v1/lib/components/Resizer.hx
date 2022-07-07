package v1.lib.components;

import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.events.Event;

/**
 * Resizer.
 * 
 * Simplest resizer implementing straightforward logic of skin resizing.
 */
class Resizer extends Component
{
	// Settings

	public var sizeSourcePath = "parent.sizeSource";

	public var resizeMode = ResizeMode.FIT_MIN;
	// Set align same as position of skin's center (LEFT and TOP if skin's 
	// center is in left top corner, CENTER and CENTER - if in center)
	public var alignH = AlignH.LEFT;
	public var alignV = AlignV.TOP;
	public var useInitialSize = true;

	// State

	private var sizeSource(default, set):DisplayObject;
	private function set_sizeSource(value:DisplayObject):DisplayObject
	{
		if (sizeSource != value)
		{
			sizeSource = value;
			if (value != null)
			{
				initialWidth = value.width;
				initialHeight = value.height;
				
				// Apply
				resize();
			}
		}
		return value;
	}

	// Getters are needed for StageResizer
	private var initialWidth(get, null):Float = 0;
	private function get_initialWidth():Float
	{
		return initialWidth;
	}
	private var initialHeight(get, null):Float = 0;
	private function get_initialHeight():Float
	{
		return initialHeight;
	}

	private var sourceWidth(get, null):Float;
	private function get_sourceWidth():Float
	{
		return sizeSource != null ? sizeSource.width : 0;
	}

	private var sourceHeight(get, null):Float;
	private function get_sourceHeight():Float
	{
		return sizeSource != null ? sizeSource.height : 0;
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

		sizeSource = resolveSkinPath(sizeSourcePath);
	}

	override private function unassignSkin():Void
	{
		sizeSource = null;

		super.unassignSkin();
	}

	/**
	 * Call each time sizeSource resized.
	 */
	public function resize():Void
	{
		if (!isEnabled || sizeSource == null || skin == null)
		{
			return;
		}

		switch resizeMode
		{
			case ResizeMode.FIT_MAX:
				// Fit full, leaving no empty spaces
				fitSkin(true, useInitialSize);
			case ResizeMode.FIT_MIN:
				// Fit stage, showing whole skin
				fitSkin(false, useInitialSize);
			case ResizeMode.STRETCH:
				// Stretch skin to stage not keeping the propoptions
				stretchSkin(useInitialSize);
		}
		switch alignH
		{
			case AlignH.LEFT:
				if (useInitialSize && initialWidth > 0)
				{
					skin.x = Math.round((sourceWidth - skin.scaleX * initialWidth) / 2);
				}
				else
				{
					skin.x = Math.round((sourceWidth - skin.width) / 2);
				}
			case AlignH.RIGHT:
				if (useInitialSize && initialWidth > 0)
				{
					skin.x = sourceWidth - Math.round((sourceWidth - skin.scaleX * initialWidth) / 2);
				}
				else
				{
					skin.x = sourceWidth - Math.round((sourceWidth - skin.width) / 2);
				}
			case AlignH.CENTER:
				skin.x = Math.round(sourceWidth / 2);
		}
		switch alignV
		{
			case AlignV.TOP:
				if (useInitialSize && initialHeight > 0)
				{
					skin.y = Math.round((sourceHeight - skin.scaleY * initialHeight) / 2);
				}
				else
				{
					skin.y = Math.round((sourceHeight - skin.height) / 2);
				}
			case AlignV.BOTTOM:
				if (useInitialSize && initialHeight > 0)
				{
					skin.y = sourceHeight - Math.round((sourceHeight - skin.scaleY * initialHeight) / 2);
				}
				else
				{
					skin.y = sourceHeight - Math.round((sourceHeight - skin.height) / 2);
				}
			case AlignV.CENTER:
				skin.y = Math.round(sourceHeight / 2);
		}
	}

	private function fitSkin(isMax:Bool=false, useInitialSize:Bool=false):Void
	{
		// Fit full, leaving no empty spaces
		if (useInitialSize && initialWidth > 0 && initialHeight > 0)
		{
			var scaleX = sourceWidth / initialWidth;
			var scaleY = sourceHeight / initialHeight;
			skin.scaleX = skin.scaleY = if (isMax) Math.max(scaleX, scaleY)
			else Math.min(scaleX, scaleY);
		}
		else if (skin != null && skin.width > 0 && skin.height > 0)
		{
			skin.width = sourceWidth;
			skin.scaleY = skin.scaleX;
			if ((isMax && skin.height < sourceHeight) ||
			(!isMax && skin.height > sourceHeight))
			{
				skin.height = sourceHeight;
				skin.scaleX = skin.scaleY;
			}
		}
	}

	private function stretchSkin(useInitialSize:Bool=false):Void
	{
		// Fit full, leaving no empty spaces
		if (useInitialSize && initialWidth > 0 && initialHeight > 0)
		{
			skin.scaleX = sourceWidth / initialWidth;
			skin.scaleY = sourceHeight / initialHeight;
		}
		else if (skin.width > 0 && skin.height > 0)
		{
			skin.width = sourceWidth;
			skin.height = sourceHeight;
		}
	}
}

/**
 * StageResizer.
 * 
 * Simplest resizer with the Stage as a size source.
 * 
 * Note: To process useInitialSize mode properly, the stage size 
 * should be in initial state when Resizer gets its skin and stage at 
 * the first time. (useInitialSize=false will work properly only 
 * if skin has same size as the stage.)
 */
class StageResizer extends Resizer
{
	// Settings

	// State

	private static var initialStageWidth:Float = 0;
	private static var initialStageHeight:Float = 0;

	override private function set_sizeSource(value:DisplayObject):DisplayObject
	{
		var stage = Std.downcast(value, Stage);
		if (stage != null)
		{
			this.stage = stage;
		}
		return super.set_sizeSource(value);
	}

	private var stage(default, set):Stage;
	private function set_stage(value:Stage):Stage
	{
		if (stage == value)
		{
			return stage;
		}

		if (stage != null)
		{
			// Listeners
			stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
		}

		stage = value;

		if (stage != null)
		{
			if (initialStageWidth <= 0 && initialStageHeight <= 0)
			{
				initialStageWidth = stage.stageWidth;
				initialStageHeight = stage.stageHeight;
			}
			// (Already in sizeSource)
			//resize();
			// Listeners
			stage.addEventListener(Event.RESIZE, stage_resizeHandler);
		}
		return stage;
	}

	override private function get_initialWidth():Float
	{
		return initialStageWidth;
	}

	override private function get_initialHeight():Float
	{
		return initialStageHeight;
	}

	override private function get_sourceWidth():Float
	{
		return stage != null ? stage.stageWidth : 0;
	}

	override private function get_sourceHeight():Float
	{
		return stage != null ? stage.stageHeight : 0;
	}

	// Init

	public function new()
	{
		super();

		// Disabled as stage used instead
		sizeSourcePath = null;
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		sizeSource = skin.stage;

		// Listeners
		skin.addEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
		skin.addEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
		skin.removeEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);

		stage = null;

		super.unassignSkin();
	}

	// Handlers

	private function skin_addedToStageHandler(event:Event):Void
	{
		stage = skin.stage;
	}

	private function skin_removedFromStageHandler(event:Event):Void
	{
		stage = skin.stage;// null
	}

	private function stage_resizeHandler(event:Event):Void
	{
		resize();
	}
}

enum abstract ResizeMode(String)
{
	// Keep proportions
	var FIT_MAX = "fitMax";
	var FIT_MIN = "fitMin";
	// Don't keep proportions
	var STRETCH = "stretch";
}

enum abstract AlignH(String)
{
	var LEFT = "left";
	var RIGHT = "right";
	var CENTER = "center";
}

enum abstract AlignV(String)
{
	var TOP = "top";
	var BOTTOM = "bottom";
	var CENTER = "center";
}
