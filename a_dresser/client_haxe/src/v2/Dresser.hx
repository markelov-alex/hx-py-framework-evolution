package v2;

import openfl.events.MouseEvent;
import openfl.display.MovieClip;
import openfl.display.InteractiveObject;

/**
 * Dresser.
 * 
 */
class Dresser extends AssetDresserScreen
{
	// Settings

	// State
	
	private var items:Array<MovieClip> = [];
	private var prevButtons:Array<InteractiveObject> = [];
	private var nextButtons:Array<InteractiveObject> = [];

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

	public function new()
	{
		super();

		items = [item1, item2, item3];
		prevButtons = [prevButton1, prevButton2, prevButton3];
		nextButtons = [nextButton1, nextButton2, nextButton3];
		
		for (item in items)
		{
			item.stop();
		}
		for (prevButton in prevButtons)
		{
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
			var button = Std.downcast(nextButton, MovieClip);
			if (button != null)
			{
				button.buttonMode = true;
			}
			// Listeners
			nextButton.addEventListener(MouseEvent.CLICK, nextButton_clickHandler);
		}
	}

	// Methods

	private function switchItem(index:Int, step:Int=1):Void
	{
		var item:MovieClip = items[index];
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
