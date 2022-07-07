package v1.dialogs;

import v0.lib.components.Button;
import v0.lib.components.Label;
import v0.lib.components.LangPanel;
import v0.lib.components.MusicToggleButton;
import v0.lib.components.SoundToggleButton;
import v1.lib.components.Dialog;
import v1.lib.components.DialogExt;
import v1.lib.components.MusicVolumeSlider;
import v1.lib.components.SoundVolumeSlider;

/**
 * SettingsDialog.
 * 
 */
class SettingsDialog extends DialogExt
{
	// Settings
	
	public static var isTestGlobalDialog = true; // Temp (debug only)
	public var isDiscardChangesOnCancel = true;
	public var soundVolumeLabelPath = "soundVolumeLabel";
	public var musicVolumeLabelPath = "musicVolumeLabel";

	// State
	
	private var soundToggleButton:SoundToggleButton;
	private var musicToggleButton:MusicToggleButton;
	private var soundVolumeSlider:SoundVolumeSlider;
	private var musicVolumeSlider:MusicVolumeSlider;
	private var soundVolumeLabel:Label;
	private var musicVolumeLabel:Label;
	private var langPanel:LangPanel;
	
	private var initialSettings:SettingsVO;
	private var isSaveChanges = false;
	private var isCloseUnsaved = false;
	
	public var confirmDialog(default, set):ConfirmDialog;
	public function set_confirmDialog(value:ConfirmDialog):ConfirmDialog
	{
		if (confirmDialog != value)
		{
			if (confirmDialog != null)
			{
				// Listeners
				confirmDialog.okSignal.remove(dialog_okSignalHandler);
//				confirmDialog.closeSignal.remove(dialog_closeSignalHandler);
			}
			confirmDialog = value;
			if (confirmDialog != null)
			{
				confirmDialog.title = "Exit";
				confirmDialog.message = "All changes will be discarded.\nAre you sure?";
				// Listeners
				confirmDialog.okSignal.add(dialog_okSignalHandler);
//				confirmDialog.closeSignal.add(dialog_closeSignalHandler);
			}
		}
		return value;
	}

	// Init

	public function new()
	{
		super();

		assetName = "menu:AssetSettingsDialog";
		okCaption = "Save";
		isModal = true;
		if (isTestGlobalDialog)
		{
			isModal = false;
		}
		// Test both
		// (For testing modality is working)
		isCloseOnClickOutside = false;
		// (For testing close on click outside)
		isCloseOnClickOutside = true;

		soundToggleButton = createComponent(SoundToggleButton);
		addChild(soundToggleButton);
		musicToggleButton = createComponent(MusicToggleButton);
		addChild(musicToggleButton);
		
		soundVolumeSlider = createComponent(SoundVolumeSlider);
		addChild(soundVolumeSlider);
		musicVolumeSlider = createComponent(MusicVolumeSlider);
		addChild(musicVolumeSlider);

		// Note: If you wish to change label texts, it's better to do in lang.yml than 
		// creating special text setters.
		soundVolumeLabel = createComponent(Label);
		soundVolumeLabel.skinPath = soundVolumeLabelPath;
		soundVolumeLabel.text = "Sound volume:";
		addChild(soundVolumeLabel);
		musicVolumeLabel = createComponent(Label);
		musicVolumeLabel.skinPath = musicVolumeLabelPath;
		musicVolumeLabel.text = "Music volume:";
		addChild(musicVolumeLabel);

		langPanel = createComponent(LangPanel);
		langPanel.skinPath = "langPanel";
		addChild(langPanel);
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Reset (for reuseable dialog)
		isSaveChanges = false;
		isCloseUnsaved = false;

		// Save initial settings
		initialSettings = {
			soundsOn: soundToggleButton.isChecked,
			musicOn: musicToggleButton.isChecked,
			soundVolume: soundVolumeSlider.value,
			musicVolume: musicVolumeSlider.value,
			lang: langPanel.lang,
		};
		// Same
//		initialSettings = {
//			soundsOn: audioManager.isSoundOn,
//			musicOn: audioManager.isMusicOn,
//			soundVolume: audioManager.soundVolume,
//			musicVolume: audioManager.musicVolume,
//			lang: langManager.currentLang,
//		};
	}

	override private function unassignSkin():Void
	{
		confirmDialog = null;
		
		// Discard changes
		if (isDiscardChangesOnCancel && !isSaveChanges)
		{
			soundToggleButton.isChecked = initialSettings.soundsOn;
			musicToggleButton.isChecked = initialSettings.musicOn;
			soundVolumeSlider.value = initialSettings.soundVolume;
			musicVolumeSlider.value = initialSettings.musicVolume;
			langPanel.lang = initialSettings.lang;
		}
		// Same
//		if (isDiscardChangesOnCancel && !isSaveChanges)
//		{
//			audioManager.isSoundOn = initialSettings.soundsOn;
//			audioManager.isMusicOn = initialSettings.musicOn;
//			audioManager.soundVolume = initialSettings.soundVolume;
//			audioManager.musicVolume = initialSettings.musicVolume;
//			langManager.currentLang = initialSettings.lang;
//		}
		
		super.unassignSkin();
	}

	private function checkCanClose():Bool
	{
		var isAnyChange = soundToggleButton.isChecked != initialSettings.soundsOn ||
			musicToggleButton.isChecked != initialSettings.musicOn ||
			soundVolumeSlider.value != initialSettings.soundVolume ||
			musicVolumeSlider.value != initialSettings.musicVolume ||
			langPanel.lang != initialSettings.lang;
		if (!isDiscardChangesOnCancel || !isAnyChange)
		{
			return true;
		}
		
		// Testing global dialogs
		ConfirmDialog.isTestGlobalDialog = isTestGlobalDialog;
		confirmDialog = Std.downcast(screens.openDialog(ConfirmDialog, isTestGlobalDialog), ConfirmDialog);
//		// To prevent click-outside when clicking on confirmDialog (will be fixed in normal way in v2)
//		clickOutside.isEnabled = false;
		return false;
	}

	// Doesn't work because of ClickOuside: when closing ConfirmDialog we thus clicking 
	// outside SettingsDialog, which opens ConfirmDialog again, and makes it closing impossible.
//	override public function close():Void
//	{
//		if (isSaveChanges || isCloseUnsaved || checkCanClose())
//		{
//			super.close();
//		}
//	}

	// Handlers

	override private function okButton_clickSignalHandler(target:Button):Void
	{
		isSaveChanges = true;
		super.okButton_clickSignalHandler(target);
	}

	private function dialog_okSignalHandler(target:Dialog):Void
	{
		isCloseUnsaved = true;
		close();
	}

	// (Still same click used by clickOutside to dispatch its clickOutsideSignal, 
	// so doesn't work)
//	private function dialog_closeSignalHandler(target:Dialog):Void
//	{
//		clickOutside.isEnabled = true;
//	}
}

typedef SettingsVO = {
	var soundsOn:Bool;
	var musicOn:Bool;
	var soundVolume:Float;
	var musicVolume:Float;
	var lang:String;
}
