package v1.lib.components;

import v0.lib.AudioManager;

/**
 * SoundVolumeSlider.
 * 
 */
class SoundVolumeSlider extends SliderExt
{
	// Settings

	// State

	private var audioManager = AudioManager.getInstance();

	// Init

	public function new()
	{
		super();

		skinPath = "soundVolumeSlider";
		ratio = audioManager.soundVolume;
	}

	// Methods

	override private function changeSignalHandler(target:Slider):Void
	{
		super.changeSignalHandler(target);

		audioManager.soundVolume = ratio;
	}
}
