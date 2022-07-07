package v0.lib;

import haxe.Exception;
import v0.lib.util.Log;
import v0.lib.ResourceManager;
/**
 * IoC.
 * 
 * IoC container.
 */
class IoC extends Base
{
	// Settings

	public var defaultAssetName = "config.yml";

	// State

	private var realTypeByTypeName:Map<String, Class<Dynamic>> = new Map();
	private var singletonByTypeName:Map<String, Dynamic> = new Map();

	private var configByName:Map<String, Map<String, Dynamic>> = new Map();
	private var configNamesByTypeName:Map<String, Array<String>> = new Map(); // (Cache)

	// Init

	public function new()
	{
		super();

		ioc = this;
	}

	override public function dispose():Void
	{
		for (instance in singletonByTypeName)
		{
			var base = Std.downcast(instance, IBase);
			if (base != null && base != this)
			{
				base.dispose();
			}
		}
		
		super.dispose();
	}

	public function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}
		var resourceManager = getSingleton(ResourceManager);

		// Get/load data
		Log.debug('Load: $assetName');
		var data = resourceManager.getData(assetName);
		if (data == null)
		{
			return;
		}

		// Apply
		// (Fill up configByName)
		for (key in Reflect.fields(data))
		{
			var configData:Dynamic = Reflect.getProperty(data, key);
			var config:Map<String, Dynamic> = configByName[key];
			if (config == null)
			{
				configByName[key] = config = new Map();
			}

			// (Update config item)
			for (name in Reflect.fields(configData))
			{
				config[name] = Reflect.getProperty(configData, name);
			}
		}

		// Resolve supers
		// (Supers work only within a file)
		// (Resolve here once to do not resolve them each time on create() called)
		for (config in configByName)
		{
			if (config["super"] != null)
			{
				applySuperConfig(config, configByName);
			}
		}
	}

	// Methods

	public function register<T>(type:Class<T>, realType:Class<T>):Void
//	public function register<T>(type:Dynamic, realType:Class<T>):Void
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
		var result = Type.createInstance(realType != null ? realType : type, []);
		if (Reflect.hasField(result, "ioc"))
		{
			Reflect.setProperty(result, "ioc", this); 
		}
		applyConfig(result, typeName, realType);
		return result;
	}

	private function applyConfig<T>(instance:T, typeName:String, ?realType:Class<Dynamic>):Void
	{
		if (instance == null)
		{
			return;
		}

		// Get all possible configNames
		var configNames = configNamesByTypeName[typeName];
		if (configNames == null)
		{
			var realTypeName:String = realType != null ? Type.getClassName(realType) : null;
			var index = typeName.lastIndexOf(".");
			var typeLastName = index != -1 ? typeName.substring(index + 1) : null;
			index = realTypeName != null ? realTypeName.lastIndexOf(".") : -1;
			var realTypeLastName = index != -1 ? realTypeName.substring(index + 1) : null;
			typeLastName = typeLastName != realTypeLastName ? typeLastName : null;
			configNames = [typeLastName, typeName, realTypeLastName, realTypeName];
			configNames = [for (cn in configNames) if (cn != null) cn];
			// (Cache)
			configNamesByTypeName[typeName] = configNames;
		}
		
		// Apply configs
		for (name in configNames)
		{
			var config = configByName[name];
			if (config != null)
			{
				// Apply config fields
				for (field => value in config)
				{
					if (!Reflect.hasField(instance, field))
					{
						Log.error('Instance: $instance doesn\'t have field: $field, so value: $value cannot be set!');
					}
					else
					{
						Reflect.setProperty(instance, field, value);
					}
				}
			}
		}
	}

	// Utility

	private static function applySuperConfig(config:Map<String, Dynamic>, configByName:Map<String, Map<String, Dynamic>>):Void
	{
		if (config == null || config["super"] == null || configByName == null)
		{
			return;
		}
		var superConfig = configByName[config["super"]];
		// Remove property "super" as it's only utilitary
		config.remove("super"); // Place here to prevent infinite recursion
		// Resolve supers recursively
		if (superConfig["super"] != null)
		{
			applySuperConfig(superConfig, configByName);
		}

		// Apply
		for (key => value in superConfig)
		{
			// Add only those properties, that haven't been already set
			if (config[key] == null)
			{
				config[key] = value;
			}
		}
	}
}
