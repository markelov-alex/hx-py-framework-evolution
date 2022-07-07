package v1.dialogs;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import v0.lib.components.Label;
import v1.lib.components.DialogExt;

/**
 * ConfirmDialog.
 * 
 * To open ColoringDialog set SettingsDialog.isTestGlobalDialog = true.
 */
class ConfirmDialog extends DialogExt
{
	// Settings

	public static var isTestGlobalDialog = true; // Temp (debug only)
	public var messageLabelPath = "messageLabel";

	// State

	private var messageLabel:Label;

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

		// Set true to test that global dialogs are really 
		// global and doesn't disappear on screen change. 
		// (ConfirmDialog opened in SettingsDialog as global.)
		// (To do that open settings dialog, change something, click 
		// Cancel, and open another screen: Dressing or Coloring)
		if (isTestGlobalDialog)
		{
			// Don't close when click to menu button
			isCloseOnClickOutside = false;
			// Allow to click on menu button
			isModal = false;
		}
		else
		{
			isCloseOnClickOutside = true;
			isModal = true;
		}

		messageLabel = createComponent(Label);
		messageLabel.text = message;
		messageLabel.skinPath = messageLabelPath;
		addChild(messageLabel);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		sprite.doubleClickEnabled = true;
		for (i in 0...container.numChildren)
		{
			var sprite:Sprite = Std.downcast(container.getChildAt(i), Sprite);
			if (sprite != null)
			{
				sprite.doubleClickEnabled = true;
			}
		}
		
		// Listeners
		sprite.doubleClickEnabled = true;
		skin.addEventListener(MouseEvent.DOUBLE_CLICK, skin_doubleClickHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(MouseEvent.DOUBLE_CLICK, skin_doubleClickHandler);
		
		super.unassignSkin();
	}
	
	// Handlers

	private function skin_doubleClickHandler(event:MouseEvent):Void
	{
		screens.openDialog(ColoringDialog);
	}
}
