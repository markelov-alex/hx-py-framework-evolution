package v0.coloring;

import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import v0.coloring.IColoringModel;
import v0.lib.components.Button;
import v0.lib.components.CheckBox;
import v0.lib.components.Component;

/**
 * Coloring.
 * 
 */
class Coloring extends Component
{
	// Settings

	public var pictureAssetNames = ["game:AssetPicture01", "game:AssetPicture02"];

	public var pictureContainerPath = "container";
	public var prevButtonPath = "prevButton";
	public var nextButtonPath = "nextButton";
	public var colorButtonPathPrefix = "color";

	// State

	private var model:IColoringModel;

	private var picture:Component;
	private var prevButton:Button;
	private var nextButton:Button;
	private var colorButtons:Array<CheckBox> = [];

	private var pictureContainer:MovieClip;

	// Init

	override private function init():Void
	{
		super.init();

		// Components
		picture = createComponent(Picture);
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
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Model
		model = ioc.getSingleton(IColoringModel);
		
		model.maxPictureIndex = pictureAssetNames.length;
		pictureContainer = Std.downcast(resolveSkinPath(pictureContainerPath), MovieClip);

		// Color buttons
		var colorButtonSkins = resolveSkinPathPrefix(colorButtonPathPrefix);
		for (i => colorButtonSkin in colorButtonSkins)
		{
			var button:ColorButton = createComponent(ColorButton);
			button.skin = colorButtonSkin;
			button.color = model.colors[i];
			colorButtons.push(button);
			// Listeners
			button.checkedSignal.add(colorButton_checkedSignalHandler);
			addChild(button);
		}

		// Apply
		refreshColorButtonsSelection();
		refreshPicture();
		
		// Listeners
		model.pictureChangeSignal.add(model_pictureChangeSignalHandler);
		model.colorChangeSignal.add(model_colorChangeSignalHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		model.pictureChangeSignal.remove(model_pictureChangeSignalHandler);
		model.colorChangeSignal.remove(model_colorChangeSignalHandler);
		
		for (colorButton in colorButtons)
		{
			// Listeners
			colorButton.checkedSignal.remove(colorButton_checkedSignalHandler);
		}
		colorButtons = [];

		pictureContainer = null;
		model = null;

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
		var pictureSkin = resourceManager.getMovieClip(assetName);
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
		var colorButton = colorButtons[model.colorIndex];
		if (colorButton != null)
		{
			colorButton.isChecked = true;
		}
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
