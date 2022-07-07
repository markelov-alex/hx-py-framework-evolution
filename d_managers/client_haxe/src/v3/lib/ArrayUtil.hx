package v3.lib;

/**
 * ArrayUtil.
 * 
 */
class ArrayUtil
{
	// Methods

	public static function equal(arr1:Array<Dynamic>, arr2:Array<Dynamic>):Bool
	{
		if (arr1 == null || arr2 == null)
		{
			return arr1 == arr2;
		}
		if (arr1.length != arr2.length)
		{
			return false;
		}
		for (i in 0...arr1.length)
		{
			if (arr1[i] != arr2[i])
			{
				return false;
			}
		}
		return true;
	}
}
