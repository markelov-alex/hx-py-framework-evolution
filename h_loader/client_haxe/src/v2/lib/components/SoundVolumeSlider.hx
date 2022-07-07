package v2.lib.components;

/**
 * SoundVolumeSlider.
 * 
 */
class SoundVolumeSlider extends SliderExt
{
	// Settings

	// State

	// Init

	override private function init():Void
	{
		super.init();
		
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
