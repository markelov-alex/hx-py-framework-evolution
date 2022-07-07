package v4.coloring;

import v0.lib.IoC;

/**
 * ColoringModel.
 * 
 */
class ColoringModel extends v3.coloring.ColoringModel
{
	// Settings
	
	// State
	
	private var service:IStorageService;

	// Init

	public function new()
	{
		super();

		init();
		// Listeners
		service.loadSignal.add(service_loadSignalHandler);
		service.stateChangeSignal.add(service_stateChangeSignalHandler);
	}

	private function init():Void
	{
		service = IoC.getInstance().create(ColoringService);
	}

	// Methods

	override public function load():Void
	{
		service.load();
	}

	override public function save():Void
	{
		service.setState(pictureStates);
	}

	// Handlers

	private function service_loadSignalHandler(value:Dynamic):Void
	{
		pictureStates = value != null ? cast value : [];
	}

	private function service_stateChangeSignalHandler(value:Dynamic):Void
	{
		pictureStates = value != null ? cast value : [];
	}
}

