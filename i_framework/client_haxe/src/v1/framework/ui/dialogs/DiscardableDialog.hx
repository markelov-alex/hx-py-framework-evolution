package v1.framework.ui.dialogs;

import v1.framework.ui.Button;
import v1.framework.ui.Component;
import v1.framework.ui.Dialog;
import v1.framework.ui.DialogExt;

/**
 * DiscardableDialog.
 * 
 */
class DiscardableDialog extends DialogExt
{
	// Settings
	
	public var isDiscardChangesOnCancel = true; // On any close except clicking on okButton
	public var confirmDialogTitle:String;
	public var confirmDialogMessage:String;
	public var confirmDialogType:Class<Component> = ConfirmDialog;

	// State
	
	private var isSaveChanges = false;
	private var isCloseUnsaved = false;

	private var confirmDialog(default, set):DialogExt;
	private function set_confirmDialog(value:DialogExt):DialogExt
	{
		if (confirmDialog != value)
		{
			if (confirmDialog != null)
			{
				// Listeners
				confirmDialog.okSignal.remove(confirmDialog_okSignalHandler);
				confirmDialog.closeSignal.remove(confirmDialog_closeSignalHandler);
			}
			
			confirmDialog = value;
			
			if (confirmDialog != null)
			{
				if (confirmDialogTitle != null)
				{
					confirmDialog.title = confirmDialogTitle;
				}
				if (confirmDialogTitle != null)
				{
					confirmDialog.message = confirmDialogMessage;
				}
				// Listeners
				confirmDialog.okSignal.add(confirmDialog_okSignalHandler);
				confirmDialog.closeSignal.add(confirmDialog_closeSignalHandler);
			}
		}
		return value;
	}

	// Init

	override private function init():Void
	{
		super.init();

		okCaption = "Save";
		confirmDialogTitle = "@confirm_dialog_title";
		confirmDialogMessage = "@confirm_dialog_message";
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Reset (for reuseable dialog)
		isSaveChanges = false;
		isCloseUnsaved = false;
		
		// Save initial settings
		saveInitial();
	}

	override private function unassignSkin():Void
	{
		confirmDialog = null;
		
		// Discard changes
		if (isDiscardChangesOnCancel && !isSaveChanges)
		{
			discardChanges();
		}
		
		super.unassignSkin();
	}
	
	// Override to save initial values to test later for changes
	private function saveInitial():Void
	{
	}
	
	// Override
	private function checkAnyChange():Bool
	{
		return false;
	}
	
	// Override to discard changes
	private function discardChanges():Void
	{
	}

	private function checkCanClose():Bool
	{
		if (!isDiscardChangesOnCancel || !checkAnyChange())
		{
			return true;
		}
		
		confirmDialog = Std.downcast(screens.openDialog(confirmDialogType), DialogExt);
		return false;
	}

	override public function close():Void
	{
		if (isSaveChanges || isCloseUnsaved || checkCanClose())
		{
			super.close();
		}
	}

	// Handlers

	override private function okButton_clickSignalHandler(target:Button):Void
	{
		isSaveChanges = true;
		super.okButton_clickSignalHandler(target);
	}

	private function confirmDialog_okSignalHandler(target:Dialog):Void
	{
		isCloseUnsaved = true;
		close();
	}

	private function confirmDialog_closeSignalHandler(target:Dialog):Void
	{
		confirmDialog = null;
	}
}
