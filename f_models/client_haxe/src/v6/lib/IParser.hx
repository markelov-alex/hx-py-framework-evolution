package v6.lib;

/**
 * IParser.
 * 
 */
interface IParser
{
	// Settings

	// State

	// Signals

	// Methods
	
	public function serialize(commands:Dynamic):Dynamic;
	public function parse(plain:Dynamic):Array<Dynamic>;
}
