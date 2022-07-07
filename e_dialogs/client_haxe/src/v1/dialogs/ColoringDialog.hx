package v1.dialogs;

import v0.coloring.ColoringScreen;
import v0.lib.components.Button;
import v1.lib.components.Drag;
import v1.lib.components.Screens;

/**
 * ColoringDialog.
 * 
 * ColoringScreen to be opened as a dialog.
 * 
 * Note: To open ColoringDialog set SettingsDialog.isTestGlobalDialog = true.
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
		Std.downcast(screens, Screens).close(this);
	}
}
