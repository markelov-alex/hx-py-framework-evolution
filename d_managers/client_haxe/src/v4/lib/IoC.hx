package v4.lib;

import v1.lib.Log;
import v3.lib.IoC in IoCOld;
import v3.lib.ResourceManager;
/**
 * IoC.
 * 
 * IoC container.
 */
class IoC extends IoCOld
{
	// Settings
	
	public var defaultAssetName = "config.yml";

	// State
	
	private var resourceManager:ResourceManager;// = ResourceManager.getInstance();
	
	private var configByName:Map<String, Map<String, Dynamic>> = new Map();
	private var configNamesByTypeName:Map<String, Array<String>> = new Map(); // (Cache)
	
	// Init

	public function new()
	{
		super();

		resourceManager = ResourceManager.getInstance();
	}

	public function load(assetName:String=null):Void
	{
		if (assetName == null)
		{
			assetName = defaultAssetName;
		}

		// Get/load data
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

	override public function create<T>(type:Class<T>):T
	{
		var result = super.create(type);
		if (result == null)
		{
			return result;
		}
		
		// Get all possible configNames
		var typeName = Type.getClassName(type);
		var configNames = configNamesByTypeName[typeName];
		if (configNames == null)
		{
			var realType = realTypeByTypeName[typeName];
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
				for (field => value in config)
				{
					if (!Reflect.hasField(result, field))
					{
						Log.error('Instance: $result doesn\'t have field: $field, so value: $value cannot be set!');
					}
					else
					{
						Reflect.setProperty(result, field, value);
					}
				}
			}
		}
		return result;
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
