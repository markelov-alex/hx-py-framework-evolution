package v1.coloring;

import v0.lib.components.Button;
import v0.lib.components.CheckBox;
import v0.lib.ResourceManager;
import v1.coloring.ColoringModel;

/**
 * Coloring.
 * 
 */
class Coloring extends v0.coloring.Coloring
{
	// Settings

	// State

	private var model:ColoringModel;

	//todo remove
	override public function set_pictureIndex(value:Int):Int
	{
		return -1;
	}

	//todo remove
	override public function set_colorIndex(value:Int):Int
	{
		return -1;
	}

	// Init

	public function new()
	{
		super();

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

		// Remove
		//super.unassignSkin();
	}

	override private function refreshPicture():Void
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

	override private function refreshColorButtonsSelection():Void
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

	override private function prevButton_clickSignalHandler(button:Button):Void
	{
		model.pictureIndex--;
	}

	override private function nextButton_clickSignalHandler(button:Button):Void
	{
		model.pictureIndex++;
	}

	override private function colorButton_checkedSignalHandler(button:CheckBox):Void
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
