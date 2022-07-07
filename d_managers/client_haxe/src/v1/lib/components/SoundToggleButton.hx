package v1.lib.components;

/**
 * SoundToggleButton.
 * 
 */
class SoundToggleButton extends CheckBox
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		skinPath = "soundToggleButton";
		// Initialize
		isChecked = AudioManager.isSoundOn;
		// Listeners
		AudioManager.toggleSoundSignal.add(audioManager_toggleSoundSignalHandler);
	}

	override public function dispose():Void
	{
		// Listeners
		AudioManager.toggleSoundSignal.remove(audioManager_toggleSoundSignalHandler);

		super.dispose();
	}

	// Methods
	
	override private function refreshChecked():Void
	{
		super.refreshChecked();

		AudioManager.isSoundOn = isChecked;
	}

	// Handlers

	private function audioManager_toggleSoundSignalHandler(value:Bool):Void
	{
		isChecked = value;
	}
}
