package v0.lib;

import haxe.Exception;

/**
 * Assert.
 * 
 */
class Assert
{
	// Static

	public static function assert(condition:Bool, message:String=null):Void
	{
		if (!condition)
		{
			message = "Fail assert: " + message.split("\n").join("");
			throw new Exception(message);
		}
	}

	public static function assertEqual<T>(a:T, b:T, message:String=null):Void
	{
		assert(a == b, '\n$a != \n$b. ${message != null ? message : ""}');
	}
}
