package v1.app.dialogs;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import v1.app.dialogs.ColoringDialog;
import v1.framework.ui.controls.Drag;

/**
 * ConfirmDialog.
 * 
 */
class ConfirmDialog extends v1.framework.ui.dialogs.ConfirmDialog
{
	// Settings

	// State

	private var drag:Drag;
	
	private var background:Sprite;
	
	// Init

	override private function init():Void
	{
		super.init();
		
		assetName = "menu:AssetConfirmDialog";
		isCloseOnClickOutside = true;
		isModal = true;

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
