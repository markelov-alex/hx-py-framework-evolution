package v3.lib;

import haxe.Exception;

/**
 * IoC.
 * 
 * IoC container.
 */
class IoC
{
	// Settings

	// State

	private static var instance:IoC;
	public static function getInstance():IoC
	{
		if (instance == null)
		{
			instance = new IoC();
		}
		return instance;
	}
	
	private var realTypeByTypeName:Map<String, Class<Dynamic>> = new Map();
	private var singletonByTypeName:Map<String, Dynamic> = new Map();

	// Init

	public function new()
	{
		if (instance != null)
		{
			throw new Exception("Singleton class can have only one instance!");
		}
		instance = this;
	}

	// Methods

	public function register<T>(type:Class<T>, realType:Class<T>):Void
	{
		var typeName = Type.getClassName(type);
		realTypeByTypeName[typeName] = realType;
	}

	/**
	 * Set some instance as singleton. 
	 * If set with another instance again, throws an exception.
	 * So, if you want to make some class a real singleton, use 
	 * this method in its constructor.
	 */
	public function setSingleton<T>(type:Class<T>, instance:T):Void
	{
		if (type == null || instance == null)
		{
			return;
		}
		var typeName = Type.getClassName(type);
		var current = singletonByTypeName[typeName];
		if (current != null && current != instance)
		{
			throw new Exception('Singleton class can have only one instance!' + 
				' current: $current new: $instance');
		}
		singletonByTypeName[typeName] = instance;
	}

	/**
	 * Get or create singleton instance for a type.
	 */
	public function getSingleton<T>(type:Class<T>):T
	{
		if (type == null)
		{
			return null;
		}
		var typeName = Type.getClassName(type);
		// Get
		var instance = singletonByTypeName[typeName];
		if (instance == null)
		{
			// Create
			instance = create(type);
			// Save by base type
			singletonByTypeName[typeName] = instance;
			// Save also by current type
			var currentType = Type.getClass(instance);
			var currentTypeName = Type.getClassName(currentType);
			singletonByTypeName[currentTypeName] = instance;
		}
		return cast instance;
	}

	/**
	 * Create another instance of some type. If another type (a subclass of a given type) 
	 * was registered earlier, this substitution will be used.
	 * Create all instances in your app only with this method to make it easy 
	 * to substitute with some of its subclasses.
	 */
	public function create<T>(type:Class<T>):T
	{
		if (type == null)
		{
			return null;
		}
		var typeName = Type.getClassName(type);
		var realType = realTypeByTypeName[typeName];
		if (realType == null)
		{
			realType = type;
		}
		return Type.createInstance(realType, []);
	}
}
