package v7.lib.util;

/**
 * Signal.
 * 
 * Signal is a callback caller supporting multiple callbacks.
 * 
 * Better than EventDispatcher:
 * 1. Not creating Event object on event occures. Just call callbacks.
 * 2. Don't need to create new Event class each time, when new event needs another set of params.
 * 3. Don't need to extend EventDispatcher. Signals can be added to any class (aggregation instead of inheritance).
 */
class Signal<T>
{
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
