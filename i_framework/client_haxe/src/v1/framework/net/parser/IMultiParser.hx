package v1.framework.net.parser;

import v1.framework.net.parser.IParser;

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
	
	public var outputVersion(default, set):String;
	public var inputVersion(default, set):String;

	public var isOutputBinary(default, null):Bool;
	public var isInputBinary(default, null):Bool;
	
}
