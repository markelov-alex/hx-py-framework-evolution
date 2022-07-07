package v1.framework.ui.audio;

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
		ratio = audio.soundVolume;
	}

	// Methods

	override private function changeSignalHandler(target:Slider):Void
	{
		super.changeSignalHandler(target);

		audio.soundVolume = ratio;
	}
}
