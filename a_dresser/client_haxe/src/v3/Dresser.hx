package v3;

import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.events.MouseEvent;

/**
 * Dresser.
 * 
 */
class Dresser
{
	// Settings
	
	public var itemNamePrefix = "item";
	public var prevButtonNamePrefix = "prevButton";
	public var nextButtonNamePrefix = "nextButton";

	// State
	
	private var items:Array<MovieClip> = [];
	private var prevButtons:Array<InteractiveObject> = [];
	private var nextButtons:Array<InteractiveObject> = [];
	
	@:isVar
	public var mc(get, set):MovieClip;
	public function get_mc():MovieClip
	{
		return mc;
	}
	public function set_mc(value:MovieClip):MovieClip
	{
		if (mc == value)
		{
			return mc;
		}

		// Unassign
		for (prevButton in prevButtons)
		{
			if (prevButton == null)
			{
				continue;
			}
			// Listeners
			prevButton.removeEventListener(MouseEvent.CLICK, prevButton_clickHandler);
		}
		for (nextButton in nextButtons)
		{
			if (nextButton == null)
			{
				continue;
			}
			// Listeners
			nextButton.removeEventListener(MouseEvent.CLICK, nextButton_clickHandler);
		}
		items = [];
		prevButtons = [];
		nextButtons = [];

		mc = value;

		if (mc != null)
		{
			// Parse
			var i = 0;
			while (true)
			{
				var item = cast mc.getChildByName(itemNamePrefix + i);
				var prevButton = cast mc.getChildByName(prevButtonNamePrefix + i);
				var nextButton = cast mc.getChildByName(nextButtonNamePrefix + i);
				if (i > 0 && item == null && prevButton == null && nextButton == null)
				{
					break;
				}
				items.push(item);
				prevButtons.push(prevButton);
				nextButtons.push(nextButton);
				i++;
			}

			// Assign
			for (item in items)
			{
				if (item == null)
					continue;
				item.stop();
			}
			for (prevButton in prevButtons)
			{
				if (prevButton == null)
					continue;
				var button = Std.downcast(prevButton, MovieClip);
				if (button != null)
				{
					button.buttonMode = true;
				}
				// Listeners
				prevButton.addEventListener(MouseEvent.CLICK, prevButton_clickHandler);
			}
			for (nextButton in nextButtons)
			{
				if (nextButton == null)
					continue;
				var button = Std.downcast(nextButton, MovieClip);
				if (button != null)
				{
					button.buttonMode = true;
				}
				// Listeners
				nextButton.addEventListener(MouseEvent.CLICK, nextButton_clickHandler);
			}
		}

		return mc;
	}

	public var state(get, set):Array<Int>;
	public function get_state():Array<Int>
	{
		return [for (item in items) item.currentFrame];
	}
	public function set_state(value:Array<Int>):Array<Int>
	{
		if (value != null)
		{
			for (i => v in value)
			{
				var item = items[i];
				if (item != null)
				{
					item.gotoAndStop(v);
				}
			}
		}
		return value;
	}
	
	// Init

	public function new(mc:MovieClip)
	{
		this.mc = mc;
	}

	// Methods

	private function switchItem(index:Int, step:Int=1):Void
	{
		var item:MovieClip = if (index >= 0 && index < items.length) items[index] else null;
		if (item != null)
		{
			var frame = (item.currentFrame + step) % item.totalFrames;
			frame = frame < 1 ? item.totalFrames - frame : frame;
			item.gotoAndStop(frame);
		}
	}
	
	// Handlers

	private function prevButton_clickHandler(event:MouseEvent):Void
	{
		var index = prevButtons.indexOf(event.currentTarget);
		switchItem(index, -1);
	}

	private function nextButton_clickHandler(event:MouseEvent):Void
	{
		var index = nextButtons.indexOf(event.currentTarget);
		switchItem(index, 1);
	}
}
