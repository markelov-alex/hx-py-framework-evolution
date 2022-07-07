package v1.lib.components;

import v0.lib.AudioManager;

/**
 * MusicVolumeSlider.
 * 
 */
class MusicVolumeSlider extends SliderExt
{
	// Settings

	// State

	private var audioManager = AudioManager.getInstance();

	// Init

	public function new()
	{
		super();

		skinPath = "musicVolumeSlider";
		ratio = audioManager.musicVolume;
	}

	// Methods
	
	// Handlers

	override private function changeSignalHandler(target:Slider):Void
	{
		super.changeSignalHandler(target);
		
		audioManager.musicVolume = ratio;
	}
}
