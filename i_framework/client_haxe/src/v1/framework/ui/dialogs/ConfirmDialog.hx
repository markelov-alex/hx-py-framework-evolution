package v1.framework.ui.dialogs;

import v1.framework.ui.DialogExt;

/**
 * ConfirmDialog.
 * 
 * Empty class, which is needed as type for substitution in IoC and 
 * calling from DiscardableDialog. Can not use jus DialogExt, because 
 * assetName should be defined inside class, not when opening the dialog.
 */
class ConfirmDialog extends DialogExt
{
	// Settings

	// State

	// Init

	override private function init():Void
	{
		super.init();

		assetName = "dialogs:AssetConfirmDialog";
	}

	// Methods

}
