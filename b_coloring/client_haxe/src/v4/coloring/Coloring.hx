package v4.coloring;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.utils.Assets;
import v4.lib.Component;
import v3.coloring.Picture;
import v3.lib.Button;
import v3.lib.CheckBox;

/**
 * Coloring.
 * 
 * Changes:
 * - Extract RadioButton functionality (changes only in refreshColorButtonsSelection()).
 */
class Coloring extends Component
{
	// Settings
	
	public var pictureAssetNames = ["coloring:AssetPicture01", "coloring:AssetPicture02"];
	public var defaultColor:Int = 0xF5DEB3;
	public var colors:Array<Int> = [
		0xEC7063, 0xAF7AC5, 0x85C1E9, 0x52BE80, 0x58D68D, 0xF4D03F, 0xF5B041, 0xCACFD2, 0xD7DBDD, 0x5D6D7E,
		0xCB4335, 0x6C3483, 0x1F618D, 0x1E8449, 0x239B56, 0xB8860B, 0xCA6F1E, 0x909497, 0x616A6B, 0x212F3D
	];

	public var pictureContainerName = "container";
	public var prevButtonName = "prevButton";
	public var nextButtonName = "nextButton";
	public var colorButtonNamePrefix = "color";

	// State
	
	private var picture:Picture;
	private var prevButton:Button;
	private var nextButton:Button;
	private var colorButtons:Array<CheckBox> = [];

	private var pictureContainer:MovieClip;
	
	private var pictureStates:Array<Array<Int>> = [];
	
	public var pictureIndex(default, set):Int;
	public function set_pictureIndex(value:Int):Int
	{
		if (value < 0)
		{
			value = 0;
		}
		if (value >= pictureAssetNames.length)
		{
			value = pictureAssetNames.length - 1;
		}
		if (pictureIndex != value)
		{
			// Save state
			if (picture != null)
			{
				pictureStates[pictureIndex] = picture.pictureState;
			}
			// Change picture
			pictureIndex = value;
			refreshPicture();
		}
		return value;
	}
	
	public var colorIndex(default, set):Int = -1;
	public function set_colorIndex(value:Int):Int
	{
		if (colorIndex != value)
		{
			colorIndex = value;
			refreshColorButtonsSelection();
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

		picture = new Picture();
		picture.defaultColor = defaultColor;
		addChild(picture);

		// Using Button components allows us to not check objects for null -- 
		// we add handlers and set properties even whether skin is null or not. 
		// That makes code shorter and prettier.
		prevButton = new Button();
		nextButton = new Button();
		prevButton.skin = if (mc != null) mc.getChildByName(prevButtonName) else null;
		nextButton.skin = if (mc != null) mc.getChildByName(nextButtonName) else null;
		addChild(prevButton);
		addChild(nextButton);
		// Listeners
		prevButton.clickSignal.add(prevButton_clickSignalHandler);
		nextButton.clickSignal.add(nextButton_clickSignalHandler);
		
		pictureContainer = if (mc != null) Std.downcast(mc.getChildByName(pictureContainerName), MovieClip) else null;
		
		// Color buttons
		var colorButtonSkins = findChildrenByNamePrefix(container, colorButtonNamePrefix);
		for (i => colorButtonSkin in colorButtonSkins)
		{
			if (colorButtonSkin == null)
			{
				continue;
			}
			var button = new ColorButton();
			button.skin = colorButtonSkin;
			button.color = colors[i];
			addChild(button);
			colorButtons.push(button);
			// Listeners
			button.checkedSignal.add(colorButton_checkedSignalHandler);
		}
		
		// Apply
		refreshColorButtonsSelection();
		refreshPicture();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		prevButton.clickSignal.remove(prevButton_clickSignalHandler);
		nextButton.clickSignal.remove(nextButton_clickSignalHandler);
		for (colorButton in colorButtons)
		{
			colorButton.checkedSignal.remove(colorButton_checkedSignalHandler);
		}
		picture = null;
		prevButton = null;
		nextButton = null;
		
		colorButtons = [];
		
		pictureContainer = null;
		pictureStates = [];
		
		super.unassignSkin();
	}

	private function findChildrenByNamePrefix(container:DisplayObjectContainer, namePrefix:String, maxAbsent=5):Array<DisplayObject>
	{
		var items = [];
		var i = 0;
		var absent = 0;
		while (true)
		{
			var item = container.getChildByName(namePrefix + i);
			if (item == null)
			{
				// Skip gaps in name (e.g. if "color1", "color2", "color5")
				absent++;
				if (absent >= maxAbsent)
				{
					// No more children
					break;
				}
			}
			else
			{
				// Another child is found
				absent = 0;
				items.push(item);
			}
			i++;
		}
		return items;
	}
	
	private function refreshPicture():Void
	{
		// Remove previous picture
		if (picture.skin != null && picture.skin.parent != null)
		{
			picture.skin.parent.removeChild(picture.skin);
		}
		// Create picture
		var assetName = pictureAssetNames[pictureIndex];
		if (assetName == null)
		{
			return;
		}
		var pictureSkin = Assets.getMovieClip(assetName);
		// Add
		fitSize(pictureSkin, pictureContainer.width, pictureContainer.height);
		pictureSkin.x = Math.floor(pictureContainer.x + (pictureContainer.width - pictureSkin.width) / 2);
		pictureSkin.y = Math.floor(pictureContainer.y + (pictureContainer.height - pictureSkin.height) / 2);
		mc.addChild(pictureSkin);
		picture.skin = pictureSkin;
		
		// Load state
		picture.pictureState = pictureStates[pictureIndex];
		
		// Update buttons
		prevButton.isEnabled = pictureIndex > 0;
		nextButton.isEnabled = pictureIndex < pictureAssetNames.length - 1;
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

	private function refreshColorButtonsSelection():Void
	{
		var colorButton = colorButtons[colorIndex];
		if (colorButton != null)
		{
			colorButton.isChecked = true;
		}
		picture.color = if (colorIndex < 0) defaultColor else colors[colorIndex];
	}
	
	// Handlers

	private function prevButton_clickSignalHandler(button:Button):Void
	{
		pictureIndex--;
	}

	private function nextButton_clickSignalHandler(button:Button):Void
	{
		pictureIndex++;
	}

	private function colorButton_checkedSignalHandler(button:CheckBox):Void
	{
		colorIndex = colorButtons.indexOf(button);
	}
}
