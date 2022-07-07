package v1.framework.ui.dialogs;

import v1.framework.ui.audio.MusicToggleButton;
import v1.framework.ui.audio.MusicVolumeSlider;
import v1.framework.ui.audio.SoundToggleButton;
import v1.framework.ui.audio.SoundVolumeSlider;
import v1.framework.ui.Label;
import v1.framework.ui.lang.LangPanel;

/**
 * SettingsDialog.
 * 
 */
class SettingsDialog extends DiscardableDialog
{
	// Settings
	
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

	// Init

	override private function init():Void
	{
		super.init();

		assetName = "dialogs:AssetSettingsDialog";
		okCaption = "Save";
		isModal = true;
		isCloseOnClickOutside = true;
		isDiscardChangesOnCancel = false;

		soundToggleButton = createComponent(SoundToggleButton);
		addChild(soundToggleButton);
		musicToggleButton = createComponent(MusicToggleButton);
		addChild(musicToggleButton);
		
		soundVolumeSlider = createComponent(SoundVolumeSlider);
		addChild(soundVolumeSlider);
		musicVolumeSlider = createComponent(MusicVolumeSlider);
		addChild(musicVolumeSlider);

		// Note: If you wish to change label texts, it's better to do it in lang.yml than 
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
	
	override private function saveInitial():Void
	{
		super.saveInitial();
		
		initialSettings = {
			soundsOn: soundToggleButton.isChecked,
			musicOn: musicToggleButton.isChecked,
			soundVolume: soundVolumeSlider.ratio,
			musicVolume: musicVolumeSlider.ratio,
			lang: langPanel.language,
		};
	}

	override private function checkAnyChange():Bool
	{
		return super.checkAnyChange() || 
			soundToggleButton.isChecked != initialSettings.soundsOn ||
			musicToggleButton.isChecked != initialSettings.musicOn ||
			soundVolumeSlider.ratio != initialSettings.soundVolume ||
			musicVolumeSlider.ratio != initialSettings.musicVolume ||
			langPanel.language != initialSettings.lang;
	}

	override private function discardChanges():Void
	{
		super.discardChanges();

		if (isDiscardChangesOnCancel && !isSaveChanges)
		{
			soundToggleButton.isChecked = initialSettings.soundsOn;
			musicToggleButton.isChecked = initialSettings.musicOn;
			soundVolumeSlider.ratio = initialSettings.soundVolume;
			musicVolumeSlider.ratio = initialSettings.musicVolume;
			langPanel.language = initialSettings.lang;
		}
	}
}

typedef SettingsVO = {
	var soundsOn:Bool;
	var musicOn:Bool;
	var soundVolume:Float;
	var musicVolume:Float;
	var lang:String;
}
