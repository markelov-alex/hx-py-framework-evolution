package v1.lib.components;

/**
 * MusicToggleButton.
 * 
 */
class MusicToggleButton extends CheckBox
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		skinPath = "musicToggleButton";
		// Initialize
		isChecked = AudioManager.isMusicOn;
		// Listeners
		AudioManager.toggleMusicSignal.add(audioManager_toggleMusicSignalHandler);
	}

	override public function dispose():Void
	{
		// Listeners
		AudioManager.toggleMusicSignal.remove(audioManager_toggleMusicSignalHandler);
		
		super.dispose();
	}

	// Methods

	override private function refreshChecked():Void
	{
		super.refreshChecked();
		
		AudioManager.isMusicOn = isChecked;
	}
	
	// Handlers

	private function audioManager_toggleMusicSignalHandler(value:Bool):Void
	{
		isChecked = value;
	}
}
