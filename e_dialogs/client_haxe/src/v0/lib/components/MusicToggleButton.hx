package v0.lib.components;

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
		isChecked = audioManager.isMusicOn;
		// Listeners
		audioManager.toggleMusicSignal.add(audioManager_toggleMusicSignalHandler);
	}

	override public function dispose():Void
	{
		// Listeners
		audioManager.toggleMusicSignal.remove(audioManager_toggleMusicSignalHandler);
		
		super.dispose();
	}

	// Methods

	override private function refreshChecked():Void
	{
		super.refreshChecked();

		audioManager.isMusicOn = isChecked;
	}
	
	// Handlers

	private function audioManager_toggleMusicSignalHandler(value:Bool):Void
	{
		isChecked = value;
	}
}
