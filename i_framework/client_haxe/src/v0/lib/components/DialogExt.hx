package v0.lib.components;

import v0.lib.util.Signal;
import v0.lib.components.Label;

/**
 * DialogExt.
 * 
 * Dialog with more common UI.
 */
class DialogExt extends Dialog
{
	// Settings
	
	public var okButtonPath = "okButton";
	public var cancelButtonPath = "cancelButton";
	public var titleLabelPath = "titleLabel";

	// State
	
	private var okButton:Button;
	private var cancelButton:Button;
	private var titleLabel:Label;

	public var okCaption(default, set):String = "OK";
	public function set_okCaption(value:String):String
	{
		if (okButton != null)
		{
			okButton.caption = value;
		}
		return okCaption = value;
	}

	public var cancelCaption(default, set):String = "Cancel";
	public function set_cancelCaption(value:String):String
	{
		if (cancelButton != null)
		{
			cancelButton.caption = value;
		}
		return cancelCaption = value;
	}

	public var title(default, set):String;
	public function set_title(value:String):String
	{
		if (titleLabel != null)
		{
			titleLabel.text = value;
		}
		return title = value;
	}

	// Signals

	public var okSignal(default, null) = new Signal<Dialog>();
	public var cancelSignal(default, null) = new Signal<Dialog>();

	// Init

	override private function init():Void
	{
		super.init();

		okButton = createComponent(Button);
		okButton.caption = okCaption;
		okButton.skinPath = okButtonPath;
		// Listeners
		okButton.clickSignal.add(okButton_clickSignalHandler);
		addChild(okButton);

		cancelButton = createComponent(Button);
		cancelButton.caption = cancelCaption;
		cancelButton.skinPath = cancelButtonPath;
		// Listeners
		cancelButton.clickSignal.add(cancelButton_clickSignalHandler);
		addChild(cancelButton);

		titleLabel = createComponent(Label);
		titleLabel.text = title;
		titleLabel.skinPath = titleLabelPath;
		addChild(titleLabel);
	}

	override public function dispose():Void
	{
		super.dispose();

		okSignal.dispose();
		cancelSignal.dispose();

		screens = null;
	}

	// Methods

	private function okButton_clickSignalHandler(target:Button):Void
	{
		// Dispatch
		okSignal.dispatch(this);

		close();
	}

	private function cancelButton_clickSignalHandler(target:Button):Void
	{
		// Dispatch
		cancelSignal.dispatch(this);

		close();
	}

	override private function closeButton_clickSignalHandler(target:Button):Void
	{
		// Dispatch
		cancelSignal.dispatch(this);

		super.closeButton_clickSignalHandler(target);
	}
}
