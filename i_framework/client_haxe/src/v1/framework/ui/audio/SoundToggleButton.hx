package v1.framework.ui.audio;

/**
 * SoundToggleButton.
 * 
 */
class SoundToggleButton extends CheckBox
{
	// Settings

	// State

	// Init

	override private function init():Void
	{
		super.init();

		skinPath = "soundToggleButton";

		// Initialize
		isChecked = audio.isSoundOn;
		// Listeners
		audio.toggleSoundSignal.add(audio_toggleSoundSignalHandler);
	}

	override public function dispose():Void
	{
		if (audio != null)
		{
			// Listeners
			audio.toggleSoundSignal.remove(audio_toggleSoundSignalHandler);
		}
		
		super.dispose();
	}

	// Methods
	
	override private function refreshChecked():Void
	{
		super.refreshChecked();

		audio.isSoundOn = isChecked;
	}

	// Handlers

	private function audio_toggleSoundSignalHandler(value:Bool):Void
	{
		isChecked = value;
	}
}
