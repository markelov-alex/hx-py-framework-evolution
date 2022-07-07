package v7.lib.util;

import haxe.PosInfos;

/**
 * Log.
 * 
 * Interface class for future logging subsystem.
 */
class Log
{
	// Settings
	
	public static var isDebug = true;
	public static var isInfo = true;
	
	// Methods

	public static function debug(message:Dynamic, ?posInfo:PosInfos):Void
	{
		if (isDebug)
		{
			Log.trace("debug: " + message, posInfo);
		}
	}

	public static function info(message:Dynamic, ?posInfo:PosInfos):Void
	{
		if (isInfo)
		{
			Log.trace(message, posInfo);
		}
	}

	public static function warn(message:Dynamic, ?posInfo:PosInfos):Void
	{
		Log.trace("WARNING! " + message, posInfo);
	}

	public static function error(message:Dynamic, ?posInfo:PosInfos):Void
	{
		Log.trace("ERROR!! " + message, posInfo);
	}

	public static function fatal(message:Dynamic, ?posInfo:PosInfos):Void
	{
		Log.trace("FATAL!!! " + message, posInfo);
	}
	
	private static dynamic function trace(v:Dynamic, infos:PosInfos):Void {
		#if (fdb || native_trace)
		var str = haxe.Log.formatOutput(v, infos);
		untyped __global__["trace"](str);
		#else
		flash.Boot.__trace(v, infos);
		#end
	}
}
