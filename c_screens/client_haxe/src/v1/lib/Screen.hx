package v1.lib;

import openfl.utils.Assets;

/**
 * Screen.
 * 
 */
class Screen extends Component
{
	// Settings

	public var assetName:String;

	public var closeButtonPath:String = "closeButton";
	
	public var exitScreenClass:Class<Screen>;

	// State
	
	private var closeButton:Button;
	
	// Signals

	public var readySignal(default, null) = new Signal<Screen>();

	// Init

	public function new()
	{
		super();

		// Won't work if assetName is set in both: consturctor (before super()) and 
		// in Screen as the latter will always overwrite the first.
		// Plus, we cannot set assetName outside the constructor, because createSkin() 
		// won't be called again.
		// So, we have to move createSkin() out of constructor.
		createSkin();
	}

	// Methods
	
	private function createSkin():Void
	{
		if (assetName == null || assetName == "")
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
		
		closeButton = new Button();
		closeButton.skin = resolveSkinPath(closeButtonPath);
		// Listeners
		closeButton.clickSignal.add(closeButton_clickSignalHandler);
		addChild(closeButton);
		
		// Dispatch
		readySignal.dispatch(this);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		closeButton.clickSignal.remove(closeButton_clickSignalHandler);
		closeButton = null;
		
		// closeButton's skin cleared in super
		super.unassignSkin();
	}

	// Simplest, but not very good and clear solution
	public function open(screenClass:Class<Screen>):Screen
	{
		if (screenClass == null)
		{
			return null;
		}
		// Create new screen
		var screen = Type.createInstance(screenClass, []);
		// Listeners
		screen.readySignal.add(screen_readySignalHandler);
		
		return screen;
	}
	
	// Handlers

	private function screen_readySignalHandler(target:Screen):Void
	{
		// Listeners
		target.readySignal.remove(screen_readySignalHandler);
		
		if (target.skin != null && skin != null && skin.parent != null)
		{
			skin.parent.addChild(target.skin);
			// Remove current screen
			skin.parent.removeChild(skin);
			skin = null;
		}
	}
	
	private function closeButton_clickSignalHandler(target:Button):Void
	{
		open(exitScreenClass);
	}
}
