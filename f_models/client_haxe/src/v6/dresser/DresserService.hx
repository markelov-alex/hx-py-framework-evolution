package v6.dresser;

/**
 * DresserService.
 * 
 * Changes:
 *  - extend another StorageService.
 */
class DresserService extends StorageProtocol
{
	// Settings

	// State

	// Init

	public function new()
	{
		super();

		transport.url = "http://127.0.0.1:5000/storage/dresser";
	}

	// Methods
}
