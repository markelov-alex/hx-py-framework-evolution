package v5.lib;

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
 *  - fix some listeners not called if some other were removed during dispatching.
 */
class Signal<T>
{
	// Test

	private static var testCallCount = 0;
	
	public static function test():Void
	{
		// Test previous Signal has a bug
		testCallCount = 0;
		var sig = new v3.lib.Signal<Dynamic>();
		sig.add(testListener);
		sig.add(testListener2); // Won't be called, although not removed
		sig.dispatch(sig);
		Assert.assertEqual(testCallCount, 1); // (should be 2)
		
		// Test bug fixed
		testCallCount = 0;
		var sig = new Signal<Dynamic>();
		sig.add(testListener);
		sig.add(testListener2); // All added listeners will be called
		sig.dispatch(sig);
		Assert.assertEqual(testCallCount, 2);
	}

	private static function testListener(target:Dynamic):Void
	{
		target.remove(testListener);
		testCallCount++;
	}

	private static function testListener2(target:Dynamic):Void
	{
		target.remove(testListener2);
		testCallCount++;
	}
	
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

	public function dispatch(target:T):Void
	{
		// Bad, as if some already called listener is removed during dispatching, 
		// all further listeners move on one step back and an iterator would skip 
		// a listener which would go next.
		//for (listener in listeners)
		// So, to make all listeners be called copy them before dispatching
		for (listener in listeners.copy())
		{
			listener(target);
		}
	}
}

class Signal2<T, C>
{
	// State

	private var listeners = new Array<(T, C)->Void>();
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
			listeners.remove(listener);
			isEmpty = listeners.length == 0;
		}
	}

	public function dispatch(param1:T, param2:C):Void
	{
		for (listener in listeners.copy())
		{
			listener(param1, param2);
		}
	}
}

class Signal3<T, C, V>
{
	// State

	private var listeners = new Array<(T, C, V)->Void>();
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
			listeners.remove(listener);
			isEmpty = listeners.length == 0;
		}
	}

	public function dispatch(param1:T, param2:C, param3:V):Void
	{
		for (listener in listeners.copy())
		{
			listener(param1, param2, param3);
		}
	}
}

class SignalDyn extends Signal<Dynamic>
{
}
