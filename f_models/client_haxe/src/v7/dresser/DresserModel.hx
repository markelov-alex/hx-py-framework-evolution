package v7.dresser;

import v0.lib.IoC;

/**
 * DresserModel.
 * 
 */
class DresserModel extends v6.dresser.DresserModel
{
	// Settings

	// State
	
	// Init

	override private function init():Void
	{
		service = IoC.getInstance().create(DresserService);
	}

	public function dispose():Void
	{
		if (service != null)
		{
			// Listeners
			service.loadSignal.remove(service_loadSignalHandler);
			service.stateChangeSignal.remove(service_stateChangeSignalHandler);
			service.itemChangeSignal.remove(service_itemChangeSignalHandler);
			cast(service, DresserService).dispose();
			service = null;
		}
	}

	// Methods
}
