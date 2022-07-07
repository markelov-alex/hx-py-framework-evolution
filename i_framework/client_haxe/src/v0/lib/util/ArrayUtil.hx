package v0.lib.util;

import v0.lib.util.Assert;
import v0.lib.util.Log;

/**
 * ArrayUtil.
 * 
 */
class ArrayUtil
{
	// Static

	public static function test():Void
	{
		test_transposeMatrix();
		test_arrayToMatrix();
	}

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

	public static function test_arrayToMatrix():Void
	{
		var array = [0, 1];
		Assert.assertEqual(Std.string(null), Std.string(arrayToMatrix(null)));
		Assert.assertEqual(Std.string([[]]), Std.string(arrayToMatrix([])));
		Assert.assertEqual(Std.string([[0]]), Std.string(arrayToMatrix([0])));
		Assert.assertEqual(Std.string([[0, 1]]), Std.string(arrayToMatrix([0, 1])));
		Assert.assertEqual(Std.string([[0], [1]]), Std.string(arrayToMatrix([0, 1], false)));
		Assert.assertEqual(Std.string([[0, 1], [2]]), Std.string(arrayToMatrix([0, 1, 2])));
		Assert.assertEqual(Std.string([[0, 2], [1]]), Std.string(arrayToMatrix([0, 1, 2], false)));
		Assert.assertEqual(Std.string([[0, 1, 2], [3, 4, 5], [6]]), Std.string(arrayToMatrix([0, 1, 2, 3, 4, 5, 6])));
		Assert.assertEqual(Std.string([[0, 3, 6], [1, 4], [2, 5]]), Std.string(arrayToMatrix([0, 1, 2, 3, 4, 5, 6], false)));
		Log.debug("Testing arrayToMatrix - OK.");
	}

	public static function arrayToMatrix<T>(array:Array<T>, isPreferHorizontal=true):Array<Array<T>>
	{
		if (array == null)
		{
			return null;
		}
		if (array.length < 2)
		{
			return [array];
		}
		var squareSideCount = Math.ceil(Math.sqrt(array.length));
		var result = [];

		var i = 0;
		var row:Array<T> = null;
		for (item in array)
		{
			if (i == 0)
			{
				row = [];
				result.push(row);
			}
			row.push(item);
			i = i + 1 >= squareSideCount ? 0 : i + 1;
		}
		if (!isPreferHorizontal)
		{
			result = transposeMatrix(result);
		}
		return result;
	}

	public static function test_transposeMatrix():Void
	{
		Assert.assertEqual(Std.string(null), Std.string(transposeMatrix(null)));
		Assert.assertEqual(Std.string([]), Std.string(transposeMatrix([])));
		Assert.assertEqual(Std.string([[]]), Std.string(transposeMatrix([[]])));
		Assert.assertEqual(Std.string([[0], [1], [2]]), Std.string(transposeMatrix([[0, 1, 2]])));
		Assert.assertEqual(Std.string([[0, 3], [1], [2]]), Std.string(transposeMatrix([[0, 1, 2], [3]])));
		Log.debug("Testing transposeMatrix - OK.");
	}

	/**
	 * Some rows in matrix can be less then the first one.
	 */
	public static function transposeMatrix<T>(m:Array<Array<T>>):Array<Array<T>>
	{
		if (m == null || m.length < 1)
		{
			return m;
		}
		var colCount = m[0].length;
		colCount = colCount < 1 ? 1 : colCount; // For [[]] -> [[]]
		var result = [for (i in 0...colCount) []];
		for (i in 0...m.length)
		{
			var row = m[i];
			for (j in 0...row.length)
			{
				var item = row[j];
				result[j][i] = item;
			}
		}
		return result;
	}
}
