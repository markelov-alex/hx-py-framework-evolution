package v1.framework.util;

#if debug
import haxe.Exception;
#end
import haxe.PosInfos;
import v1.framework.util.Log;

/**
 * Assert.
 * 
 */
class Assert
{
	// Static

	public static function assert(condition:Bool, message:String=null, ?posInfo:PosInfos):Void
	{
		if (!condition)
		{
			Log.fatal("Fail assert: " + (message != null ? message : ""), posInfo);
			#if debug
			message = message.split("\n").join("");
			throw new Exception(message);
			#else
			#end
		}
	}

	public static function assertEqual<T>(a:T, b:T, message:String=null, ?posInfo:PosInfos):Void
	{
		assert(a == b, '\n$a != \n$b. ${message != null ? message : ""}', posInfo);
	}
}
