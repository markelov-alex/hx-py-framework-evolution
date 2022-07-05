package v1;

import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import openfl.utils.Assets;

/**
 * Coloring.
 * 
 */
class Coloring
{
	// Settings
	
	public var pictureAssetNames = ["coloring:AssetPicture01", "coloring:AssetPicture02"];
	public var defaultColor:Int = 0xF5DEB3;
	public var colors:Array<Int> = [
		0xEC7063, 0xAF7AC5, 0x85C1E9, 0x52BE80, 0x58D68D, 0xF4D03F, 0xF5B041, 0xCACFD2, 0xD7DBDD, 0x5D6D7E,
		0xCB4335, 0x6C3483, 0x1F618D, 0x1E8449, 0x239B56, 0xB8860B, 0xCA6F1E, 0x909497, 0x616A6B, 0x212F3D
	];
	
	public var containerName = "container";
	public var colorButtonNamePrefix = "color";
	public var prevButtonName = "prevButton";
	public var nextButtonName = "nextButton";
	public var colorFillName = "fill";
	public var colorCheckedName = "checked";

	// State
	
	private var container:MovieClip;
	private var colorButtons:Array<MovieClip> = [];
	private var prevButton:InteractiveObject;
	private var nextButton:InteractiveObject;
	private var picture:MovieClip;
	private var pictureItems:Array<MovieClip> = [];
	private var pictureStates:Array<Array<Int>> = [];
	
	public var mc(default, set):MovieClip;
	public function set_mc(value:MovieClip):MovieClip
	{
		if (mc == value)
		{
			return value;
		}
		if (mc != null)
		{
			unassignSkin();
		}
		mc = value;
		if (mc != null)
		{
			assignSkin();
		}

		return value;
	}
	
	public var pictureIndex(default, set):Int;
	public function set_pictureIndex(value:Int):Int
	{
		if (value < 0)
			value = 0;
		if (value >= pictureAssetNames.length)
			value = pictureAssetNames.length - 1;
		if (pictureIndex != value)
		{
			// Save state
			pictureStates[pictureIndex] = pictureState;
			// Change picture
			pictureIndex = value;
			refreshPicture();
			// Load state
			pictureState = pictureStates[pictureIndex];
		}
		return value;
	}

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
	
	public var colorIndex(default, set):Int = -1;
	public function set_colorIndex(value:Int):Int
	{
		if (colorIndex != value)
		{
			colorIndex = value;
			refreshColorRadioButtonsSelection();
		}
		return value;
	}
	
	// Init

	public function new(mc:MovieClip)
	{
		this.mc = mc;
	}

	// Methods

	private function assignSkin():Void
	{
		// Parse
		if (mc != null)
		{
			container = Std.downcast(mc.getChildByName(containerName), MovieClip);
			prevButton = Std.downcast(mc.getChildByName(prevButtonName), InteractiveObject);
			nextButton = Std.downcast(mc.getChildByName(nextButtonName), InteractiveObject);
			refreshPicture();
		}
		colorButtons = [];
		var i = 0;
		var absent = 0;
		var maxAbsent = 5;
		while (true)
		{
			var colorButton:MovieClip = Std.downcast(mc.getChildByName(colorButtonNamePrefix + i), MovieClip);
			if (colorButton == null)
			{
				absent++;
				if (absent >= maxAbsent)
				{
					break;
				}
			}
			else
			{
				absent = 0;
				colorButtons.push(colorButton);
			}
			i++;
		}

		// Assign
		for (i => colorButton in colorButtons)
		{
			if (colorButton == null)
			{
				continue;
			}
			//var button:Sprite = Std.downcast(colorButton, Sprite);
			var button:Sprite = cast colorButton;
			if (button != null)
			{
				button.buttonMode = true;
			}
			var color = colors[i];
			//if (color != null)
			{
				var fill = colorButton.getChildByName(colorFillName);
				applyColor(if (fill != null) fill else colorButton, color);
			}
			// Listeners
			colorButton.addEventListener(MouseEvent.CLICK, colorButton_clickHandler);
		}
		refreshColorRadioButtonsSelection();
		var button:Sprite = Std.downcast(prevButton, Sprite);
		if (button != null)
		{
			button.buttonMode = true;
		}
		var button:Sprite = Std.downcast(nextButton, Sprite);
		if (button != null)
		{
			button.buttonMode = true;
		}
		// Listeners
		if (prevButton != null)
		{
			prevButton.addEventListener(MouseEvent.CLICK, prevButton_clickHandler);
		}
		if (nextButton != null)
		{
			nextButton.addEventListener(MouseEvent.CLICK, nextButton_clickHandler);
		}
	}

	private function unassignSkin():Void
	{
		// Unassign
		for (colorButton in colorButtons)
		{
			if (colorButton == null)
			{
				continue;
			}
			// Listeners
			colorButton.removeEventListener(MouseEvent.CLICK, colorButton_clickHandler);
		}
		if (prevButton != null)
		{
			// Listeners
			prevButton.removeEventListener(MouseEvent.CLICK, prevButton_clickHandler);
		}
		if (nextButton != null)
		{
			// Listeners
			nextButton.removeEventListener(MouseEvent.CLICK, nextButton_clickHandler);
		}
		container = null;
		colorButtons = [];
		prevButton = null;
		nextButton = null;
		picture = null;
		pictureItems = [];
		pictureStates = [];
	}
	
	private function refreshPicture():Void
	{
		// Unassign
		if (picture != null)
		{
			if (picture.parent != null)
			{
				picture.parent.removeChild(picture);
			}
			picture = null;
			for (item in pictureItems)
			{
				// Listeners
				item.removeEventListener(MouseEvent.CLICK, pictureItem_clickHandler);
			}
			pictureItems = [];
		}
		
		// Create picture
		var assetName = pictureAssetNames[pictureIndex];
		if (assetName == null)
		{
			return;
		}
		picture = Assets.getMovieClip(assetName);
		
		// Assign
		if (picture != null)
		{
			fitSize(picture, container.width, container.height);
			picture.x = Math.floor(container.x + (container.width - picture.width) / 2);
			picture.y = Math.floor(container.y + (container.height - picture.height) / 2);
			mc.addChild(picture);
			pictureItems = [];
			parsePictureItems(picture, pictureItems);
			for (item in pictureItems)
			{
				applyColor(item, defaultColor);
				// Listeners
				item.addEventListener(MouseEvent.CLICK, pictureItem_clickHandler);
			}
		}
		if (prevButton != null)
		{
			prevButton.mouseEnabled = pictureIndex > 0;
		}
		if (nextButton != null)
		{
			nextButton.mouseEnabled = pictureIndex < pictureAssetNames.length - 1;
		}
	}

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

	private function fitSize(object:DisplayObject, width:Float, height:Float):Void
	{
		if (object == null)
		{
			return;
		}
		object.width = width;
		object.scaleY = object.scaleX;
		if (object.height > height)
		{
			object.height = height;
			object.scaleX = object.scaleY;
		}
	}

	private function refreshColorRadioButtonsSelection():Void
	{
		var colorIndex = this.colorIndex;
		for (i => colorButton in colorButtons)
		{
			var checked = colorButton.getChildByName(colorCheckedName);
			if (checked != null)
			{
				checked.visible = i == colorIndex;
			}
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

	private function prevButton_clickHandler(event:MouseEvent):Void
	{
		pictureIndex--;
	}

	private function nextButton_clickHandler(event:MouseEvent):Void
	{
		pictureIndex++;
	}

	private function colorButton_clickHandler(event:MouseEvent):Void
	{
		colorIndex = colorButtons.indexOf(event.currentTarget);
	}

	private function pictureItem_clickHandler(event:MouseEvent):Void
	{
		var color = if (colorIndex < 0) defaultColor else colors[colorIndex];
		//if (color != null)
		{
			applyColor(event.currentTarget, color);
		}
		trace(pictureState);
	}
}
