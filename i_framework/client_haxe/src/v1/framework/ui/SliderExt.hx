package v1.framework.ui;

import v1.framework.ui.Button;
import v1.framework.ui.Label;

/**
 * SliderExt.
 * 
 * Slider with buttons and labels.
 */
class SliderExt extends Slider
{
	// Settings
	
	public var valueLabelPath = "valueLabel";
	public var minusButtonPath = "minusButton";
	public var plusButtonPath = "plusButton";
	
	public var buttonRatioStep:Float = 0.05;
	public var trackRatioStep:Float = 0.1;
	public var valueFormatter:(Float)->String;

	// State

	private var valueLabel:Label;
	private var minusButton:Button;
	private var plusButton:Button;
	private var trackButton:Button;

	// Init

	override private function init():Void
	{
		super.init();

		valueLabel = createComponent(Label);
		valueLabel.skinPath = valueLabelPath;
		addChild(valueLabel);

		minusButton = createComponent(Button);
		minusButton.skinPath = minusButtonPath;
		// Listeners
		minusButton.clickSignal.add(minusButton_clickSignalHandler);
		addChild(minusButton);

		plusButton = createComponent(Button);
		plusButton.skinPath = plusButtonPath;
		// Listeners
		plusButton.clickSignal.add(plusButton_clickSignalHandler);
		addChild(plusButton);

		trackButton = createComponent(Button);
		trackButton.skinPath = trackPath;
		trackButton.useHandCursor = false;
		// Listeners
		trackButton.clickSignal.add(trackButton_clickSignalHandler);
		addChild(trackButton);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		refreshValueLabel();
	}

	private function refreshValueLabel():Void
	{
		valueLabel.text = valueFormatter != null ? valueFormatter(value) : Std.string(value);
	}

	// Handlers

	private function changeSignalHandler(target:Slider):Void
	{
		refreshValueLabel();
	}

	private function minusButton_clickSignalHandler(target:Button):Void
	{
		ratio -= buttonRatioStep;
	}

	private function plusButton_clickSignalHandler(target:Button):Void
	{
		ratio += buttonRatioStep;
	}

	private function trackButton_clickSignalHandler(target:Button):Void
	{
		var thumb = drag.skin;
		if (thumb == null || thumb.parent == null)
		{
			return;
		}

		var isBackward = if (drag.isVertical) thumb.parent.mouseY < thumb.y else
			thumb.parent.mouseX < thumb.x;
		ratio += trackRatioStep * (isBackward ? -1 : 1);
	}
}
