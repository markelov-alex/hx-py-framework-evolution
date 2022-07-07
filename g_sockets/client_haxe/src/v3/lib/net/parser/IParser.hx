package v3.lib.net.parser;

/**
 * IParser.
 * 
 */
interface IParser
{
	// Methods
	
	/**
	 * Command or list of command objects to plain string or bytes.
	 */
	public function serialize(object:Dynamic):Dynamic;
	/**
	 * Plain string or bytes to list of command objects.
	 */
	public function parse(plain:Dynamic):Array<Dynamic>;
}
