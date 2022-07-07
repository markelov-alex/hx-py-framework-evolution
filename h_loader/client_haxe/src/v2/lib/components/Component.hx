package v2.lib.components;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.display.SimpleButton;
import openfl.display.Sprite;
import v0.lib.util.Signal;

/**
 * Component.
 * 
 * Note: refreshXxx() methods not guaranteed from skin==null, 
 * so you must check it everytime.
 * 
 * Changes:
 *  - remove getInstance(),
 *  - get ResourceManager via IoC,
 *  - add also Audio and LangManager (because it costs nothing, and we 
 *  often forget to clear references to them in other components),
 *  - as components creation needs IoC, all subcomponent creation moves from 
 *  constructor to new init(), called from ioc setter,
 *  - moving initialization from constructor to separate method init() (and 
 *  calling init() and dispose() in ioc setter) make component reuseable, as 
 *  we cannot call constructor after an instance was disposed, but init() can.
 *  Now, one can dispose the component in two ways, by calling dispose() or by 
 *  setting ioc = null. Also spread this concept on other classes, like 
 *  Application, adding init()-dispose() pair there.
 */
class Component extends Base
{
	// Settings

	// (Set null to test that it won't overwrite values defined in subclasses)
	public var assetName:String = null;
	// If empty "", parent's skin will be taken; if null, no skin will be set.
	public var skinPath:String = "";

	// State
	
	private var resourceManager:ResourceManager;
	private var audioManager:AudioManager;
	private var langManager:LangManager;
	
	private var _screens:Screens;
	public var screens(get, null):Screens;
	public function get_screens():Screens
	{
		return _screens = _screens == null ? ioc.getSingleton(Screens) : _screens;
	}

	/**
	 * "Template method" for parsing skin, adding listeners, etc, 
	 * and clearing it up.
	 */
	public var skin(default, set):DisplayObject;
	public function set_skin(value:DisplayObject):DisplayObject
	{
		if (skin == value)
		{
			// Same value
			return value;
		}
		if (skin != null)
		{
			unassignSkin();
		}
		// Set
		skin = value;
		interactiveObject = Std.downcast(value, InteractiveObject);
		simpleButton = Std.downcast(value, SimpleButton);
		container = Std.downcast(value, DisplayObjectContainer);
		sprite = Std.downcast(value, Sprite);
		mc = Std.downcast(value, MovieClip);
		if (skin != null)
		{
			isAssigningSkin = true;
			assignSkin();
			isAssigningSkin = false;
		}

		// Dispatch
		readySignal.dispatch(this);
		return value;
	}
	private var isAssigningSkin = false;
	public var interactiveObject(default, null):InteractiveObject;
	public var simpleButton(default, null):SimpleButton;
	public var container(default, null):DisplayObjectContainer;
	public var sprite(default, null):Sprite;
	public var mc(default, null):MovieClip;

	public var parent(default, set):Component;
	private function set_parent(value:Component):Component
	{
		if (parent != value)
		{
			// Dispose skin created by assetName
			if (assetName != null && value == null)
			{
				skin = null;
			}
			// Set
			parent = value;
			// Create skin by assetName (parent.skin should be also 
			// non null for children with "parent" in skinPath)
			if (assetName != null && parent != null && parent.skin != null)
			{
				// (All component properties should be set by now 
				// (before added to its parent).)
				// (Skin's parent could be changed here if needed)
				setSkin();
			}
		}
		return value;
	}
	public var children(default, null):Array<Component> = [];
	// Children added during assignSkin() called and 
	// to be removed automatically in unassignSkin()
	private var temporaryChildren:Array<Component> = [];

	@:isVar public var isEnabled(get, set):Bool = true;
	public function get_isEnabled():Bool
	{
		return isEnabled && isParentEnabled;
	}
	public function set_isEnabled(value:Bool):Bool
	{
		if (isEnabled != value)
		{
			isEnabled = value;
			refreshEnabled();
		}
		return value;
	}

	/**
	 * Disabling all children on isEnabled = false.
	 */
	@:isVar public var isParentEnabled(default, set):Bool = true;
	public function set_isParentEnabled(value:Bool):Bool
	{
		if (isParentEnabled != value)
		{
			isParentEnabled = value;

			// Set isParentEnabled recursively
			refreshEnabled();
		}
		return value;
	}

	public var visible(default, set):Null<Bool>;
	public function set_visible(value:Null<Bool>):Null<Bool>
	{
		if (visible != value)
		{
			visible = value;
			refreshVisible();
		}
		return value;
	}

	// Signals

	public var readySignal(default, null) = new Signal<Component>();

	// Init

	// Override to change default settings
//	public function new()
//	{
//		super();
//	}

	// Override to reset settings to defaults and create subcomponents
	override private function init():Void
	{
		super.init();
		
		// Note: Can't set _screens here because Screens extends Component
		// and when we'll set ioc to Screens instance itself it'll try to 
		// get ioc.getSingleton(Screens) which is not yet set.
		
		resourceManager = ioc.getSingleton(ResourceManager);
		audioManager = ioc.getSingleton(AudioManager);
		langManager = ioc.getSingleton(LangManager);
	}
	
	override public function dispose():Void
	{
		readySignal.dispose();

		if (parent != null)
		{
			parent.removeChild(this);
		}
		skin = null;

		// Clear up all children components created in init()
		for (child in children.copy())
		{
			child.dispose();
		}

		_screens = null;
		resourceManager = null;
		audioManager = null;
		langManager = null;

		super.dispose();
	}

	// Methods

	/**
	 * Set skin from parent using assetName and skinPath properties.
	 * If assetName is used, skinPath is ignored.
	 */
	private function setSkin():Void
	{
		if (skin != null)
		{
			// Already set
			return;
		}

		// Create by assetName
		if (assetName != null)
		{
			resourceManager.createMovieClip(assetName, function(mc:MovieClip)
			{
				// Get only a part of created MovieClip 
				// (not efficient approach: it's not good to create whole MC only to use 
				// one of its parts -- we won't allow that)
				// skin = resolveSkinPath(skinPath, mc);

				// Add to display list first
				if (parent != null && parent.container != null)
				{
					parent.container.addChild(mc);
				}
				// Set
				skin = mc;
			});
		}
		// Get from parent.skin by skinPath
		else if (skinPath != null)
		{
			skin = resolveSkinPath(skinPath, parent.container);
		}
	}

	/**
	 * Entry point to a component. Skin is guaranteed to be not null.
	 */
	// Override
	private function assignSkin():Void
	{
		// Set skin for children using skinPath or assetName
		for (child in children.copy())
		{
			child.setSkin();
		}

		// Apply
		refreshEnabled();
		refreshVisible();
	}

	/**
	 * Exit point from a component. 
	 * Clear up all links to a skin before it's removed.
	 * Make all actions in reverse order than in assignSkin().
	 */
	// Override
	private function unassignSkin():Void
	{
		// Clear up all children
		for (child in children.copy())
		{
			child.skin = null;
		}
		
		// Remove skin created by assetName
		if (assetName != null && skin.parent != null)
		{
			skin.parent.removeChild(skin);
		}

		// Remove children added inside assignSkin()
		for (child in temporaryChildren.copy())
		{
			//removeChild(child);
			// Suppose, components created where they added, 
			// so they should be not just removed, but disposed
			child.dispose();
		}
		temporaryChildren = [];
	}

	/**
	 * Add child only after it completely set up, because 
	 * it's likely, that addChild() will create/set child's skin.
	 */
	public function addChild(child:Component):Component
	{
		if (child == null || child.parent == this)
		{
			return child;
		}

		// Remove from previous
		if (child.parent != null)
		{
			// (Don't call removeChild() to do not dispose skin created by assetName)
			//child.parent.removeChild(child);
			child.parent.children.remove(child);
		}

		// Add
		if (isAssigningSkin)
		{
			// As sometimes component creation depends on skin content, we should allow 
			// that creation inside assignSkin(), but insure they will be removed anyway 
			// by adding them to special list:
			//Log.warn('Adding child: $child inside $this.assignSkin(). ' + 
			//		 "It\'s recommended to create and add all child components in constructor, " +  
			//		 "not in assignSkin()! Otherwise you should remove it in unassignSkin()!");
			temporaryChildren.push(child);
		}
		children.push(child);
		// Important to be after added to children if parent is a setter.
		child.parent = this;
		return child;
	}

	public function removeChild(child:Component):Component
	{
		if (child == null || child.parent != this)
		{
			return null;
		}
		// Should be before children.remove(child) as child.parent = null sets also child.skin = null 
		// and child.unassignSkin() may expect the component among other parent's children. 
		// All changes on removing must appear in reversed order as in adding.
		child.parent = null;
		children.remove(child);
		return child;
	}

	private function refreshEnabled():Void
	{
		var isEnabled = this.isEnabled;
		if (interactiveObject != null)
		{
			interactiveObject.mouseEnabled = isEnabled;
		}

		// Set isParentEnabled recursively
		if (isParentEnabled || !isEnabled)
		{
			for (child in children)
			{
				child.isParentEnabled = isEnabled;
			}
		}
	}

	private function refreshVisible():Void
	{
		if (skin != null)
		{
			if (visible == null)
			{
				// Set visible by skin
				visible = skin.visible;
			}
			else
			{
				skin.visible = visible;
			}
		}
	}
	
	// Utility

	private function createComponent<T>(type:Dynamic):T
	{
		return ioc.create(type);
	}

	/**
	 * Aims:
	 * 1. Replace:
 	 * 		some = if (container != null) container.getChildByName(someName) else null;
 	 * 	with:	
 	 * 		some = resolveSkinPath(somePath);
 	 * 2. Get nested object by name chain like this: "parent.buttons.menuButton1".
 	 * 
 	 * Skip for path=null, use source for path="".
	 */
	private function resolveSkinPath(path:String, source=null):DisplayObject
	{
		if (path == null)
		{
			return null;	
		}
		if (source == null)
		{
			source = container;
		}
		if (source == null || path == "")
		{
			return source;
		}
		var result:DisplayObject = null;
		var pathParts:Array<String> = path.split(".");
		var count = pathParts.length;
		for (i in 0...count)
		{
			if (source == null)
			{
				return null;
			}
			var name = pathParts[i];
			result = if (name == "parent") source.parent else source.getChildByName(name);
			if (result == null)
			{
				return null;
			}
			if (i < count - 1)
			{
				source = Std.downcast(result, DisplayObjectContainer);
			}
		}
		return result;
	}

	/**
	 * Get all display objects with names beginning with pathPrefix.
	 */
	private function resolveSkinPathPrefix(pathPrefix:String, maxGapCount=5):Array<DisplayObject>
	{
		var items = [];
		var i = 0;
		var absent = 0;
		while (true)
		{
			var item = resolveSkinPath(pathPrefix + i);
			if (item == null)
			{
				// Skip gaps in name (e.g. if "color1", "color2", "color5")
				absent++;
				if (absent >= maxGapCount)
				{
					// No more children
					break;
				}
			}
			else
			{
				// Another child is found
				absent = 0;
				items.push(item);
			}
			i++;
		}
		return items;
	}
}
