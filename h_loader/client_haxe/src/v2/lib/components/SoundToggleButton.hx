package v2.lib.components;

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
		isChecked = audioManager.isSoundOn;
		// Listeners
		audioManager.toggleSoundSignal.add(audioManager_toggleSoundSignalHandler);
	}

	override public function dispose():Void
	{
		if (audioManager != null)
		{
			// Listeners
			audioManager.toggleSoundSignal.remove(audioManager_toggleSoundSignalHandler);
		}

		super.dispose();
	}

	// Methods
	
	override private function refreshChecked():Void
	{
		super.refreshChecked();

		audioManager.isSoundOn = isChecked;
	}

	// Handlers

	private function audioManager_toggleSoundSignalHandler(value:Bool):Void
	{
		isChecked = value;
	}
}
