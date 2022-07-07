package v7.lib.net.parser;

/**
 * IMultiParser.
 * 
 */
interface IMultiParser extends IParser
{
	// Settings

	public var parserByVersion:Map<String, Dynamic>;
	
	// State

	public var versions(get, null):Array<String>;
	
	public var version(default, set):String;
	
}
