package v6.coloring;

/**
 * ColoringService.
 * 
 * Changes:
 *  - extend another StorageService.
 */
class ColoringService extends StorageProtocol
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		transport.url = "http://127.0.0.1:5000/storage/coloring";
	}

	// Methods
}
