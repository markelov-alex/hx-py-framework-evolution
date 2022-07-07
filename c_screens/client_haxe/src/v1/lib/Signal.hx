package v1.lib;

import v1.lib.Assert;

/**
 * Signal.
 * 
 * Signal is a callback caller supporting multiple callbacks.
 * 
 * Better than EventDispatcher:
 * 1. Not creating Event object on event occures. Just call callbacks.
 * 2. Don't need to create new Event class each time, when new event needs another set of params.
 * 3. Don't need to extend EventDispatcher. Signals can be added to any class (aggregation instead of inheritance).
 * 
 * Changes:
 *  - fix bug when listener is still called, though it was removed during dispatching.
 */
class Signal<T>
{
	// Test

	private static var testCallCount = 0;

	public static function test():Void
	{
		testCallCount = 0;
		var sig = new PrevSignal<Dynamic>();
		sig.add(testListener1);
		// (Will be called, though removed in testListener())
		sig.add(testListener2);
		sig.dispatch(sig);
		Assert.assertEqual(testCallCount, 2); // (Should be 1)
		
		testCallCount = 0;
		var sig = new Signal<Dynamic>();
		sig.add(testListener1);
		// (Will be removed before called)
		sig.add(testListener2);
		sig.dispatch(sig);
		Assert.assertEqual(testCallCount, 1);
		
		testCallCount = 0;
		var sig = new Signal2<Dynamic, Dynamic>();
		sig.add(testListener3);
		// (Will be removed before called)
		sig.add(testListener4);
		sig.dispatch(sig, null);
		Assert.assertEqual(testCallCount, 1);
		
		testCallCount = 0;
		var sig = new Signal3<Dynamic, Dynamic, Dynamic>();
		sig.add(testListener5);
		// (Will be removed before called)
		sig.add(testListener6);
		sig.dispatch(sig, null, null);
		Assert.assertEqual(testCallCount, 1);
	}

	private static function testListener1(sig:Dynamic):Void
	{
		testCallCount++;
		sig.remove(testListener1);
		sig.remove(testListener2);
	}

	// To be never called
	private static function testListener2(sig:Dynamic):Void
	{
		testCallCount++;
	}

	private static function testListener3(sig:Dynamic, ?a):Void
	{
		testCallCount++;
		sig.remove(testListener3);
		sig.remove(testListener4);
	}

	// To be never called
	private static function testListener4(sig:Dynamic, ?a):Void
	{
		testCallCount++;
	}

	private static function testListener5(sig:Dynamic, ?a, ?b):Void
	{
		testCallCount++;
		sig.remove(testListener5);
		sig.remove(testListener6);
	}

	// To be never called
	private static function testListener6(sig:Dynamic, ?a, ?b):Void
	{
		testCallCount++;
	}

	// State

	private var listeners = new Array<(T)->Void>();
	public var isEmpty(default, null):Bool = true;
	private var isDispatching = false;

	// Init

	public function new()
	{
	}

	public function dispose():Void
	{
		listeners.resize(0);
	}

	// Methods

	public function add(listener:(T)->Void):Void
	{
		if (listener != null && !listeners.contains(listener))
		{
			listeners.push(listener);
			isEmpty = false;
		}
	}

	public function remove(listener:(T)->Void):Void
	{
		if (listener != null)
		{
			if (isDispatching)
			{
				listeners[listeners.indexOf(listener)] = null;
			}
			else
			{
				listeners.remove(listener);
			}
			isEmpty = listeners.length == 0;
		}
	}

	public function dispatch(target:T):Void
	{
		// Bad, as if we destroy some object which has signals while dispatching, 
		// the listeners would be still called, though they shouldn't.
//		for (listener in listeners.copy())
		// So, the solution is to replace removed listeners with nulls which would be 
		// skipped, and after dispatch completed, remove that nulls.
		isDispatching = true;
		for (listener in listeners)
		{
			if (listener != null)
			{
				listener(target);
			}
		}
		isDispatching = false;
		// Remove all removed during dispatching (all nulls)
		listeners = [for (l in listeners) if (l != null) l];
	}
}

class PrevSignal<T>
{
	// State

	private var listeners = new Array<(T)->Void>();
	public var isEmpty(default, null):Bool = true;

	// Init

	public function new()
	{
	}

	public function dispose():Void
	{
		listeners.resize(0);
	}

	// Methods

	public function add(listener:(T)->Void):Void
	{
		if (listener != null && !listeners.contains(listener))
		{
			listeners.push(listener);
			isEmpty = false;
		}
	}

	public function remove(listener:(T)->Void):Void
	{
		if (listener != null)
		{
			listeners.remove(listener);
			isEmpty = listeners.length == 0;
		}
	}

	public function dispatch(param1:T):Void
	{
		for (listener in listeners.copy())
		{
			listener(param1);
		}
	}
}

class Signal2<T, C>
{
	// State

	private var listeners = new Array<(T, C)->Void>();
	public var isEmpty(default, null):Bool = true;
	private var isDispatching = false;

	// Init

	public function new()
	{
	}

	public function dispose():Void
	{
		listeners.resize(0);
	}

	// Methods

	public function add(listener:(T, C)->Void):Void
	{
		if (listener != null && !listeners.contains(listener))
		{
			listeners.push(listener);
			isEmpty = false;
		}
	}

	public function remove(listener:(T, C)->Void):Void
	{
		if (listener != null)
		{
			if (isDispatching)
			{
				listeners[listeners.indexOf(listener)] = null;
			}
			else
			{
				listeners.remove(listener);
			}
			isEmpty = listeners.length == 0;
		}
	}

	public function dispatch(param1:T, param2:C):Void
	{
		isDispatching = true;
		for (listener in listeners)
		{
			if (listener != null)
			{
				listener(param1, param2);
			}
		}
		isDispatching = false;
		// Remove all removed during dispatching (all nulls)
		listeners = [for (l in listeners) if (l != null) l];
	}
}

class Signal3<T, C, V>
{
	// State

	private var listeners = new Array<(T, C, V)->Void>();
	public var isEmpty(default, null):Bool = true;
	private var isDispatching = false;

	// Init

	public function new()
	{
	}

	public function dispose():Void
	{
		listeners.resize(0);
	}

	// Methods

	public function add(listener:(T, C, V)->Void):Void
	{
		if (listener != null && !listeners.contains(listener))
		{
			listeners.push(listener);
			isEmpty = false;
		}
	}

	public function remove(listener:(T, C, V)->Void):Void
	{
		if (listener != null)
		{
			if (isDispatching)
			{
				listeners[listeners.indexOf(listener)] = null;
			}
			else
			{
				listeners.remove(listener);
			}
			isEmpty = listeners.length == 0;
		}
	}

	public function dispatch(param1:T, param2:C, param3:V):Void
	{
		isDispatching = true;
		for (listener in listeners)
		{
			if (listener != null)
			{
				listener(param1, param2, param3);
			}
		}
		isDispatching = false;
		// Remove all removed during dispatching (all nulls)
		listeners = [for (l in listeners) if (l != null) l];
	}
}

class SignalDyn extends Signal<Dynamic>
{
}
