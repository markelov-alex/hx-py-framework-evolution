package v1.framework.net.parser;

/**
 * IParser.
 * 
 */
interface IParser
{
	// Settings

	public var isBinary(default, null):Bool;

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
