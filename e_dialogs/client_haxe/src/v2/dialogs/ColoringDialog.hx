package v2.dialogs;

import v1.lib.components.Drag;
import v2.coloring.ColoringScreen;
import v2.lib.components.Button;
import v2.lib.components.Screens;

/**
 * ColoringDialog.
 * 
 * ColoringScreen to be opened as a dialog.
 */
class ColoringDialog extends ColoringScreen
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		assetName = "game:AssetColoringScreen";

		// Make draggable
		var drag = createComponent(Drag);
		addChild(drag);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Disable centering on resize because can be moved by user
		resizer.alignH = null;
		resizer.alignV = null;
	}

	// Handlers

	override private function closeButton_clickSignalHandler(target:Button):Void
	{
		Screens.getInstance().close(this);
	}
}
