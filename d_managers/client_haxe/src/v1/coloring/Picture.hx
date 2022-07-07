package v1.coloring;

import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import v1.lib.components.Component;

/**
 * Picture.
 * 
 */
class Picture extends Component
{
	// Settings
	
	public var defaultColor:Int;

	// State

	private var pictureItems:Array<MovieClip> = [];
	
	// Current selected color
	public var color:Int;

	public var pictureState(get, set):Array<Int>;
	public function get_pictureState():Array<Int>
	{
		return [for (item in pictureItems) item.transform.colorTransform.color];
	}
	public function set_pictureState(value:Array<Int>):Array<Int>
	{
		if (value != null)
		{
			for (i => v in value)
			{
				var item = pictureItems[i];
				if (item != null)
				{
					applyColor(item, v);
				}
			}
		}
		return value;
	}

	// Init

	public function new()
	{
		super();

		// Skin set directly by Coloring
		skinPath = null;
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		if (mc != null)
		{
			pictureItems = [];
			parsePictureItems(mc, pictureItems);
			for (item in pictureItems)
			{
				applyColor(item, defaultColor);
				// Listeners
				item.addEventListener(MouseEvent.CLICK, pictureItem_clickSignalHandler);
			}
		}
	}

	override private function unassignSkin():Void
	{
		for (item in pictureItems)
		{
			// Listeners
			item.removeEventListener(MouseEvent.CLICK, pictureItem_clickSignalHandler);
		}
		pictureItems = [];
		
		super.unassignSkin();
	}

	/**
	 * Find recursively all movie clips without other movie clips inside.
	 */
	private function parsePictureItems(picture:MovieClip, pictureItems:Array<MovieClip>):Void
	{
		var mcCount = 0;
		for (i in 0...picture.numChildren)
		{
			var item = Std.downcast(picture.getChildAt(i), MovieClip);
			if (item != null)
			{
				mcCount++;
				parsePictureItems(item, pictureItems);
			}
		}
		if (mcCount == 0)
		{
			pictureItems.push(picture);
		}
	}

	private function applyColor(object:DisplayObject, color:Int=1):Void
	{
		if (object != null)
		{
			var ct = new ColorTransform();
			ct.color = color;
			object.transform.colorTransform = ct;
		}
	}
	
	// Handlers

	private function pictureItem_clickSignalHandler(event:MouseEvent):Void
	{
		applyColor(event.currentTarget, color);
	}
}
