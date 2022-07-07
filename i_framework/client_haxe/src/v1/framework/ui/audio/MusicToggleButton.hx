package v1.framework.ui.audio;

/**
 * MusicToggleButton.
 * 
 */
class MusicToggleButton extends CheckBox
{
	// Settings

	// State

	// Init

	override private function init():Void
	{
		super.init();

		skinPath = "musicToggleButton";
		
		// Initialize
		isChecked = audio.isMusicOn;
		// Listeners
		audio.toggleMusicSignal.add(audio_toggleMusicSignalHandler);
	}

	override public function dispose():Void
	{
		if (audio != null)
		{
			// Listeners
			audio.toggleMusicSignal.remove(audio_toggleMusicSignalHandler);
		}

		super.dispose();
	}

	// Methods

	override private function refreshChecked():Void
	{
		super.refreshChecked();

		audio.isMusicOn = isChecked;
	}
	
	// Handlers

	private function audio_toggleMusicSignalHandler(value:Bool):Void
	{
		isChecked = value;
	}
}
