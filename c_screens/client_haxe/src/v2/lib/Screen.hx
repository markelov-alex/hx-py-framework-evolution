package v2.lib;

import openfl.display.DisplayObject;
import openfl.utils.Assets;
import v1.lib.Button;
import v1.lib.Component;
import v1.lib.Signal;

/**
 * Screen.
 * 
 */
class Screen extends Component
{
	// Settings

	// (Set null to test that it won't overwrite values defined in subclasses)
	public var assetName:String = null;

	public var closeButtonPath:String = "closeButton";
	
	public var exitScreenClass:Class<Screen> = null;

	// State
	
	private var closeButton:Button;

	override public function set_skin(value:DisplayObject):DisplayObject
	{
		if (skin != value)
		{
			var result = super.set_skin(value);

			// Dispatch
			readySignal.dispatch(this);
			return result;
		}
		return value;
	}

	override private function set_parent(value:Component):Component
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
			// Create skin by assetName
			if (assetName != null && value != null)
			{
				// (All component properties should be set by now 
				// (before added to its parent).)
				// (Skin's parent could be changed here if needed)
				createSkin();
			}
		}
		return value;
	}
	
	private var screens(get, null):Screens;
	private function get_screens():Screens
	{
		return Std.downcast(parent, Screens);
	}

	// Signals

	public var readySignal(default, null) = new Signal<Screen>();

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods
	
	// TODO move to ResourceManager.createMovieClip(callback)
	private function createSkin():Void
	{
		if (assetName == null || skin != null)
		{
			return;
		}
		
		// As Assets.exists() doesn't work and Assets.getMovieClip() throws exception 
		// if library is not loaded, we load all libraries: preloaded and not.
		// That's why listening of readySignal is required to add skin to display list.

		// If library is loaded or not
		if (assetName.indexOf(":") != -1)
		{
			var libraryName = assetName.split(":")[0];
			Assets.loadLibrary(libraryName).onComplete(function(library)
			{
				var mc = Assets.getMovieClip(assetName);
				skin = mc;
			});
		}
		// Only if library is loaded
		else
		{
			skin = Assets.getMovieClip(assetName);
		}
	}

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		// Add created by assetName skin to display list
		if (assetName != null && skin.parent == null &&
			parent != null && parent.container != null)
		{
			parent.container.addChild(skin);
		}
		
		closeButton = new Button();
		closeButton.skin = resolveSkinPath(closeButtonPath);
		// Listeners
		closeButton.clickSignal.add(closeButton_clickSignalHandler);
		addChild(closeButton);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		closeButton.clickSignal.remove(closeButton_clickSignalHandler);
		closeButton = null;
		
		// Remove skin created by assetName
		if (assetName != null && skin.parent != null)
		{
			skin.parent.removeChild(skin);
		}

		// closeButton's skin cleared in super
		super.unassignSkin();
	}
	
	// Handlers
	
	private function closeButton_clickSignalHandler(target:Button):Void
	{
		screens.open(exitScreenClass);
	}
}
