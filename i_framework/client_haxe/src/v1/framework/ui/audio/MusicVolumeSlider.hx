package v1.framework.ui.audio;

/**
 * MusicVolumeSlider.
 * 
 */
class MusicVolumeSlider extends SliderExt
{
	// Settings

	// State

	// Init

	override private function init():Void
	{
		super.init();
		
		skinPath = "musicVolumeSlider";
		ratio = audio.musicVolume;
	}

	// Methods
	
	// Handlers

	override private function changeSignalHandler(target:Slider):Void
	{
		super.changeSignalHandler(target);

		audio.musicVolume = ratio;
	}
}
