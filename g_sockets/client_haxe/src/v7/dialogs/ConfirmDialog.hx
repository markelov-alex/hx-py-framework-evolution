package v7.dialogs;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import v7.lib.components.DialogExt;
import v7.lib.components.Drag;
import v7.lib.components.Label;

/**
 * ConfirmDialog.
 * 
 */
class ConfirmDialog extends DialogExt
{
	// Settings

	public var messageLabelPath = "messageLabel";

	// State

	private var messageLabel:Label;
	private var drag:Drag;
	
	private var background:Sprite;
	
	public var message(default, set):String;
	public function set_message(value:String):String
	{
		if (messageLabel != null)
		{
			messageLabel.text = value;
		}
		return message = value;
	}

	// Init

	public function new()
	{
		super();

		assetName = "menu:AssetConfirmDialog";
		isCloseOnClickOutside = true;
		isModal = true;

		messageLabel = createComponent(Label);
		messageLabel.text = message;
		messageLabel.skinPath = messageLabelPath;
		addChild(messageLabel);

		drag = createComponent(Drag);
		// If dragging is always enabled, it will be dragged with modal background.
		// (// Skip same click that initiated current component creation except modal in one movie clip and set 
		// path to drag.skinPath, if you want to drag with isModal==true.)
		drag.isEnabled = !isModal;
		addChild(drag);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		background = Std.downcast(resolveSkinPath("background"), Sprite);
		if (background != null)
		{
			background.doubleClickEnabled = true;
			// Listeners
			background.addEventListener(MouseEvent.DOUBLE_CLICK, background_doubleClickHandler);
		}
	}

	override private function unassignSkin():Void
	{
		if (background != null)
		{
			// Listeners
			background.removeEventListener(MouseEvent.DOUBLE_CLICK, background_doubleClickHandler);
			background = null;
		}

		super.unassignSkin();
	}

	// Handlers

	private function background_doubleClickHandler(event:MouseEvent):Void
	{
		screens.openDialog(ColoringDialog);
	}
}
