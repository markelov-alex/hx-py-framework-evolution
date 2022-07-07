package v1.framework.ui;

import v1.framework.ui.Label;
import v1.framework.util.Signal;

/**
 * DialogExt.
 * 
 * Dialog with more common UI.
 */
class DialogExt extends Dialog
{
	// Settings
	
	public var titleLabelPath = "titleLabel";
	public var messageLabelPath = "messageLabel";
	public var okButtonPath = "okButton";
	public var cancelButtonPath = "cancelButton";

	// State
	
	private var titleLabel:Label;
	private var messageLabel:Label;
	private var okButton:Button;
	private var cancelButton:Button;

	public var title(default, set):String;
	public function set_title(value:String):String
	{
		if (titleLabel != null)
		{
			titleLabel.text = value;
		}
		return title = value;
	}

	public var message(default, set):String;
	public function set_message(value:String):String
	{
		if (messageLabel != null)
		{
			messageLabel.text = value;
		}
		return message = value;
	}

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

	// Signals

	public var okSignal(default, null) = new Signal<Dialog>();
	public var cancelSignal(default, null) = new Signal<Dialog>();

	// Init

	override private function init():Void
	{
		super.init();

		titleLabel = createComponent(Label);
		titleLabel.text = title;
		titleLabel.skinPath = titleLabelPath;
		addChild(titleLabel);

		messageLabel = createComponent(Label);
		messageLabel.text = message;
		messageLabel.skinPath = messageLabelPath;
		addChild(messageLabel);

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
