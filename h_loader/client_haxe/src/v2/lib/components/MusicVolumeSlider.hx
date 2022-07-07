package v2.lib.components;

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
