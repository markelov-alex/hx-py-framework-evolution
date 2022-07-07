package v0.coloring;

import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import v0.lib.components.Button;
import v0.lib.components.CheckBox;
import v0.lib.components.Component;
import v0.lib.ResourceManager;

/**
 * Coloring.
 * 
 */
class Coloring extends Component
{
	// Settings

	public var pictureAssetNames = ["game:AssetPicture01", "game:AssetPicture02"];
	public var defaultColor:Int = 0xF5DEB3;
	public var colors:Array<Int> = [
		0xEC7063, 0xAF7AC5, 0x85C1E9, 0x52BE80, 0x58D68D, 0xF4D03F, 0xF5B041, 0xCACFD2, 0xD7DBDD, 0x5D6D7E,
		0xCB4335, 0x6C3483, 0x1F618D, 0x1E8449, 0x239B56, 0xB8860B, 0xCA6F1E, 0x909497, 0x616A6B, 0x212F3D
	];

	public var pictureContainerPath = "container";
	public var prevButtonPath = "prevButton";
	public var nextButtonPath = "nextButton";
	public var colorButtonPathPrefix = "color";

	// State

	private var model:ColoringModel;

	private var picture:Picture;
	private var prevButton:Button;
	private var nextButton:Button;
	private var colorButtons:Array<CheckBox> = [];

	private var pictureContainer:MovieClip;

	// Init

	public function new()
	{
		super();

		// Components
		picture = createComponent(Picture);
		picture.defaultColor = defaultColor;
		addChild(picture);

		prevButton = createComponent(Button);
		nextButton = createComponent(Button);
		prevButton.skinPath = prevButtonPath;
		nextButton.skinPath = nextButtonPath;
		// Listeners
		prevButton.clickSignal.add(prevButton_clickSignalHandler);
		nextButton.clickSignal.add(nextButton_clickSignalHandler);
		// Add component only at the end
		addChild(prevButton);
		addChild(nextButton);

		// Model
		model = ioc.getSingleton(ColoringModel);
		// Listeners
		model.pictureChangeSignal.add(model_pictureChangeSignalHandler);
		model.colorChangeSignal.add(model_colorChangeSignalHandler);

		if (model.defaultColor >= 0)
		{
			defaultColor = model.defaultColor;
		}
		if (model.colors != null)
		{
			colors = model.colors;
		}
	}

	override public function dispose():Void
	{
		super.dispose();

		if (model != null)
		{
			// Listeners
			model.pictureChangeSignal.remove(model_pictureChangeSignalHandler);
			model.colorChangeSignal.remove(model_colorChangeSignalHandler);
			model = null;
		}
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		model.maxPictureIndex = pictureAssetNames.length;
		pictureContainer = Std.downcast(resolveSkinPath(pictureContainerPath), MovieClip);

		// Color buttons
		var colorButtonSkins = resolveSkinPathPrefix(colorButtonPathPrefix);
		for (i => colorButtonSkin in colorButtonSkins)
		{
			var button:ColorButton = createComponent(ColorButton);
			button.skin = colorButtonSkin;
			button.color = colors[i];
			colorButtons.push(button);
			// Listeners
			button.checkedSignal.add(colorButton_checkedSignalHandler);
			addChild(button);
		}

		// Apply
		refreshColorButtonsSelection();
		refreshPicture();
	}

	override private function unassignSkin():Void
	{
		// Listeners
		for (colorButton in colorButtons)
		{
			colorButton.checkedSignal.remove(colorButton_checkedSignalHandler);
		}
		colorButtons = [];

		pictureContainer = null;

		super.unassignSkin();
	}

	private function refreshPicture():Void
	{
		if (mc == null)
		{
			return;
		}

		var pictureIndex = model.pictureIndex;
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
		var pictureSkin = ResourceManager.getInstance().getMovieClip(assetName);
		// Add
		fitSize(pictureSkin, pictureContainer.width, pictureContainer.height);
		pictureSkin.x = Math.floor(pictureContainer.x + (pictureContainer.width - pictureSkin.width) / 2);
		pictureSkin.y = Math.floor(pictureContainer.y + (pictureContainer.height - pictureSkin.height) / 2);
		mc.addChild(pictureSkin);
		picture.skin = pictureSkin;

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
		var colorIndex = model.colorIndex;
		var colorButton = colorButtons[colorIndex];
		if (colorButton != null)
		{
			colorButton.isChecked = true;
		}
		picture.color = if (colorIndex < 0 || colorIndex >= colors.length)
			defaultColor else colors[colorIndex];
	}

	// Handlers

	private function prevButton_clickSignalHandler(button:Button):Void
	{
		model.pictureIndex--;
	}

	private function nextButton_clickSignalHandler(button:Button):Void
	{
		model.pictureIndex++;
	}

	private function colorButton_checkedSignalHandler(button:CheckBox):Void
	{
		model.colorIndex = colorButtons.indexOf(button);
	}

	private function model_pictureChangeSignalHandler(value:Int):Void
	{
		refreshPicture();
	}

	private function model_colorChangeSignalHandler(value:Int):Void
	{
		refreshColorButtonsSelection();
	}
}
