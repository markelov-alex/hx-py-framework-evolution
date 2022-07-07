package v7.coloring;

import v0.lib.IoC;

/**
 * ColoringModel.
 * 
 */
class ColoringModel extends v6.coloring.ColoringModel
{
	// Settings
	
	// State

	// Init

	override private function init():Void
	{
		service = IoC.getInstance().create(ColoringService);
	}

	public function dispose():Void
	{
		if (service != null)
		{
			// Listeners
			service.loadSignal.remove(service_loadSignalHandler);
			service.stateChangeSignal.remove(service_stateChangeSignalHandler);
			cast(service, ColoringService).dispose();
			service = null;
		}
	}

	// Methods
}

