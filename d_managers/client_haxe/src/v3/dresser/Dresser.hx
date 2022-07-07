package v3.dresser;

import openfl.display.MovieClip;
import v3.lib.components.Button;
import v3.lib.components.Component;

/**
 * Dresser.
 * 
 * Main component implementing dressing games functionality.
 */
class Dresser extends Component
{
	// Settings
	
	public var itemPathPrefix = "item";
	public var prevButtonPathPrefix = "prevButton";
	public var nextButtonPathPrefix = "nextButton";

	// State
	
	private var prevButtons:Array<Button> = [];
	private var nextButtons:Array<Button> = [];
	
	private var items:Array<MovieClip> = [];
	
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

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		if (mc == null)
		{
			return;
		}
		
		// Parse
		var prevButtonSkins = resolveSkinPathPrefix(prevButtonPathPrefix);
		var nextButtonSkins = resolveSkinPathPrefix(nextButtonPathPrefix);
		for (prevButtonSkin in prevButtonSkins)
		{
			var button = createComponent(Button);
			button.skin = prevButtonSkin;
			addChild(button);
			prevButtons.push(button);
			// Listeners
			button.clickSignal.add(prevButton_clickSignalHandler);
		}
		for (nextButtonSkin in nextButtonSkins)
		{
			var button = createComponent(Button);
			button.skin = nextButtonSkin;
			addChild(button);
			nextButtons.push(button);
			// Listeners
			button.clickSignal.add(nextButton_clickSignalHandler);
		}
		
		items = cast resolveSkinPathPrefix(itemPathPrefix);

		// Apply
		for (item in items)
		{
			item.stop();
		}
	}

	override private function unassignSkin():Void
	{
		for (button in prevButtons)
		{
			// Listeners
			button.clickSignal.remove(prevButton_clickSignalHandler);
		}
		for (button in nextButtons)
		{
			// Listeners
			button.clickSignal.remove(nextButton_clickSignalHandler);
		}
		prevButtons = [];
		nextButtons = [];

		items = [];
		
		super.unassignSkin();
	}

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

	private function prevButton_clickSignalHandler(target:Button):Void
	{
		var index = prevButtons.indexOf(target);
		switchItem(index, -1);
	}

	private function nextButton_clickSignalHandler(target:Button):Void
	{
		var index = nextButtons.indexOf(target);
		switchItem(index, 1);
	}
}
