package v0.dialogs;

import v0.lib.components.Button;
import v0.lib.components.Dialog;
import v0.lib.components.DialogExt;
import v0.lib.components.Label;
import v0.lib.components.LangPanel;
import v0.lib.components.MusicToggleButton;
import v0.lib.components.MusicVolumeSlider;
import v0.lib.components.SoundToggleButton;
import v0.lib.components.SoundVolumeSlider;

/**
 * SettingsDialog.
 * 
 */
class SettingsDialog extends DialogExt
{
	// Settings
	
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
			}
			confirmDialog = value;
			if (confirmDialog != null)
			{
				confirmDialog.title = "Exit";
				confirmDialog.message = "All changes will be discarded.\nAre you sure?";
				// Listeners
				confirmDialog.okSignal.add(dialog_okSignalHandler);
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
		// Test both: false and true
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
			soundVolume: soundVolumeSlider.ratio,
			musicVolume: musicVolumeSlider.ratio,
			lang: langPanel.lang,
		};
	}

	override private function unassignSkin():Void
	{
		confirmDialog = null;
		
		// Discard changes
		if (isDiscardChangesOnCancel && !isSaveChanges)
		{
			soundToggleButton.isChecked = initialSettings.soundsOn;
			musicToggleButton.isChecked = initialSettings.musicOn;
			soundVolumeSlider.ratio = initialSettings.soundVolume;
			musicVolumeSlider.ratio = initialSettings.musicVolume;
			langPanel.lang = initialSettings.lang;
		}
		
		super.unassignSkin();
	}

	private function checkCanClose():Bool
	{
		var isAnyChange = soundToggleButton.isChecked != initialSettings.soundsOn ||
			musicToggleButton.isChecked != initialSettings.musicOn ||
			soundVolumeSlider.ratio != initialSettings.soundVolume ||
			musicVolumeSlider.ratio != initialSettings.musicVolume ||
			langPanel.lang != initialSettings.lang;
		if (!isDiscardChangesOnCancel || !isAnyChange)
		{
			return true;
		}
		
		confirmDialog = Std.downcast(screens.openDialog(ConfirmDialog), ConfirmDialog);
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

	private function dialog_okSignalHandler(target:Dialog):Void
	{
		isCloseUnsaved = true;
		close();
	}
}

typedef SettingsVO = {
	var soundsOn:Bool;
	var musicOn:Bool;
	var soundVolume:Float;
	var musicVolume:Float;
	var lang:String;
}
