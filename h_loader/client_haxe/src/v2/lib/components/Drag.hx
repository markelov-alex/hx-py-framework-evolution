package v2.lib.components;

import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import v0.lib.util.Signal;
import v2.lib.components.Component;

/**
 * Drag.
 * 
 */
class Drag extends Component
{
	// Settings
	
	// Linear bounds
	public var trackPath = "parent.track";
	// Rectangular bounds
	public var boundsPath = "parent.bounds";

	// Make skin bounds do not exceed dragging area, not only skin's center
	public var isConsiderSkinBounds = true;

	public var useHandCursor(default, set):Bool = true;
	public function set_useHandCursor(value:Bool):Bool
	{
		if (sprite != null)
		{
			sprite.buttonMode = isEnabled && value;
		}
		return useHandCursor = value;
	}
	
	// State
	
	private var track:DisplayObject;
	private var bounds:DisplayObject;
	private var stage:Stage;

	private var boundsRect:Rectangle;
	private var mouseDownX:Float;
	private var mouseDownY:Float;
	
	// Which side is the longest
	public var isVertical(default, null) = false;
	public var isDragging(default, null) = false;

	// The longest side of bounds is main
	public var ratioMain(get, set):Float;
	public function get_ratioMain():Float
	{
		return if (isVertical) ratioY else ratioX;
	}
	public function set_ratioMain(value:Float):Float
	{
		if (isVertical)
		{
			return ratioY = value;
		}
		else
		{
			return ratioX = value;
		}
	}
	public var ratioSecondary(get, set):Float;
	public function get_ratioSecondary():Float
	{
		return if (!isVertical) ratioY else ratioX;
	}
	public function set_ratioSecondary(value:Float):Float
	{
		if (!isVertical)
		{
			return ratioY = value;
		}
		else
		{
			return ratioX = value;
		}
	}

	private var _ratioX:Float = -1;
	public var ratioX(get, set):Float;
	public function get_ratioX():Float
	{
		return if (_ratioX >=0) _ratioX else _ratioX = getRatioXBySkin();
	}
	public function set_ratioX(value:Float):Float
	{
		// Set -1 to invalidate
		value = value != -1 && value < 0 ? 0 : (value > 1 ? 1 : value);
		if (_ratioX != value)
		{
			_ratioX = value;
			if (_ratioX >= 0)
			{
				applyRatioXOnSkin();
			}

			// Dispatch
			changeSignal.dispatch(this);
		}
		return value;
	}

	private var _ratioY:Float = -1;
	public var ratioY(get, set):Float;
	public function get_ratioY():Float
	{
		return if (_ratioY >=0) _ratioY else _ratioY = getRatioYBySkin();
	}
	public function set_ratioY(value:Float):Float
	{
		// Set -1 to invalidate
		value = value != -1 && value < 0 ? 0 : (value > 1 ? 1 : value);
		if (_ratioY != value)
		{
			_ratioY = value;
			if (_ratioY >= 0)
			{
				applyRatioYOnSkin();
			}

			// Dispatch
			changeSignal.dispatch(this);
		}
		return value;
	}

	// Signals

	public var changeSignal(default, null) = new Signal<Drag>();

	// Init

//	override private function init():Void
//	{
//		super.init();
//	}

	override public function dispose():Void
	{
		changeSignal.dispose();
		
		super.dispose();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		track = resolveSkinPath(trackPath);
		bounds = resolveSkinPath(boundsPath);
		stage = skin.stage;
		
		refreshBounds();

		// Apply ratio
		if (_ratioX >= 0)
		{
			applyRatioXOnSkin();
		}
		if (_ratioY >= 0)
		{
			applyRatioYOnSkin();
		}
		// Apply useHandCursor
		if (sprite != null)
		{
			sprite.buttonMode = isEnabled && useHandCursor;
		}

		// Listeners
		skin.addEventListener(MouseEvent.MOUSE_DOWN, skin_mouseDownHandler);
		if (stage != null)
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
		}
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(MouseEvent.MOUSE_DOWN, skin_mouseDownHandler);
		if (stage != null)
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, stage_mouseUpHandler);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
		}
		
		track = null;
		bounds = null;
		stage = null;
		
		super.unassignSkin();
	}
	
	// Call on track/bounds or skin (if isConsiderSkinBounds=true) size changed
	public function refreshBounds():Void
	{
		var source:DisplayObject = track != null ? track : bounds;
		if (source == null)
		{
			boundsRect = null;
			return;
		}
		
		isVertical = source.width < source.height;
		boundsRect = source.getBounds(skin.parent);
		if (isConsiderSkinBounds)
		{
			var skinRect = skin.getBounds(skin);
			boundsRect.top -= skinRect.top;
			boundsRect.bottom -= skinRect.bottom;
			boundsRect.left -= skinRect.left;
			boundsRect.right -= skinRect.right;
		}
		if (source == track)
		{
			if (isVertical)
			{
				boundsRect.left = boundsRect.right = skin.x;
			}
			else
			{
				boundsRect.top = boundsRect.bottom = skin.y;
			}
		}

		// Use bounds
		if (boundsRect != null)
		{
			var x = skin.x;
			var y = skin.y;
			skin.x = x < boundsRect.left ? boundsRect.left : (x > boundsRect.right ? boundsRect.right : x);
			skin.y = y < boundsRect.top ? boundsRect.top : (y > boundsRect.bottom ? boundsRect.bottom : y);
		}
	}

	private function getRatioXBySkin():Float
	{
		if (skin == null || boundsRect == null)
		{
			return 0;
		}
		return (skin.x - boundsRect.left) / boundsRect.width;
	}

	private function applyRatioXOnSkin():Void
	{
		if (skin != null && boundsRect != null)
		{
			skin.x = _ratioX * boundsRect.width + boundsRect.left;
		}
	}

	private function getRatioYBySkin():Float
	{
		if (skin == null || boundsRect == null)
		{
			return 0;
		}
		return (skin.y - boundsRect.top) / boundsRect.height;
	}

	private function applyRatioYOnSkin():Void
	{
		if (skin != null && boundsRect != null)
		{
			skin.y = _ratioY * boundsRect.height + boundsRect.top;
		}
	}
	
	// Handlers

	private function skin_mouseDownHandler(event:MouseEvent):Void
	{
		if (!isEnabled)
		{
			return;
		}

		// Start dragging
		isDragging = true;
		// (The way to do not use globalToLocal(new Point(event.stageX, event.stageY)))
		mouseDownX = skin.parent.mouseX - skin.x;
		mouseDownY = skin.parent.mouseY - skin.y;

		// Listeners
		if (skin.stage != null)
		{
			skin.stage.addEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
		}
	}

	private function stage_mouseUpHandler(event:MouseEvent):Void
	{
		// Stop dragging
		isDragging = false;
		// Listeners
		if (skin.stage != null)
		{
			skin.stage.removeEventListener(MouseEvent.MOUSE_MOVE, stage_mouseMoveHandler);
		}
	}
	
	private function stage_mouseMoveHandler(event:MouseEvent):Void
	{
		if (!isEnabled)
		{
			return;
		}
		
		// Calculate
		var x = skin.parent.mouseX - mouseDownX;
		var y = skin.parent.mouseY - mouseDownY;
		// Use bounds
		if (boundsRect != null)
		{
			x = x < boundsRect.left ? boundsRect.left : (x > boundsRect.right ? boundsRect.right : x);
			y = y < boundsRect.top ? boundsRect.top : (y > boundsRect.bottom ? boundsRect.bottom : y);
		}
		
		// Update
		skin.x = x;
		skin.y = y;
		// Invalidate ratio
		ratioX = -1;
		ratioY = -1;

		// Dispatch
		changeSignal.dispatch(this);
	}
}
