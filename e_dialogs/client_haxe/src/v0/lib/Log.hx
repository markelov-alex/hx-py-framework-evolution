package v0.lib;

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

	public static function debug(message:Dynamic):Void
	{
		if (isDebug)
		{
			trace("debug: " + message);
		}
	}

	public static function info(message:Dynamic):Void
	{
		if (isInfo)
		{
			trace(message);
		}
	}

	public static function warn(message:Dynamic):Void
	{
		trace("WARNING! " + message);
	}

	public static function error(message:Dynamic):Void
	{
		trace("ERROR!! " + message);
	}

	public static function fatal(message:Dynamic):Void
	{
		trace("FATAL!!! " + message);
	}
}
