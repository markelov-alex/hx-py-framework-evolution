package v7.lib.components;

import openfl.events.MouseEvent;
import v7.lib.IoC;
import v7.lib.util.Log;

/**
 * Screens.
 * 
 * Container and root component for all screens and dialogs.
 */
class Screens extends Component
{
	// Settings
	
	public var isReuseComponents = true;

	// State

	public static function getInstance():Screens
	{
		return IoC.getInstance().getSingleton(Screens);
	}

	public var currentScreen(default, null):Screen;
	
	private var currentScreenClass:Class<Screen>;

	private var dialogStack:Array<Component> = []; // To disable all under modal
	private var localDialogs:Array<Component> = []; // To close dialogs related to previous screen
	private var pool:Map<String, Component> = new Map();
	private var isClickingOnCurrentScreen = false;
	private var isDialogJustOpened = false;

	// Init

	public function new()
	{
		super();

		// Throws exception if more than 1 instance
		IoC.getInstance().setSingleton(Screens, this);
	}

	override public function dispose():Void
	{
		for (instance in pool)
		{
			instance.dispose();
		}
		pool.clear();

		for (dialog in dialogStack)
		{
			dialog.dispose();
		}
		dialogStack.resize(0);
		localDialogs.resize(0);

		if (currentScreen != null)
		{
			currentScreen.dispose();
			currentScreen = null;
		}
		
		super.dispose();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		// Listeners
		skin.addEventListener(MouseEvent.CLICK, skin_clickCapturedHandler, true);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(MouseEvent.CLICK, skin_clickCapturedHandler, true);
		
		super.unassignSkin();
	}

	public function open(type:Class<Screen>):Screen
	{
		if (currentScreenClass == type)
		{
			return currentScreen;
		}

		// Close previous
		for (dialog in localDialogs)
		{
			close(dialog);
		}
		close(currentScreen);
		if (currentScreen != null)
		{
			// Listeners
			currentScreen.readySignal.remove(component_readySignalHandler);
		}

		// Open new
		currentScreenClass = type;
		currentScreen = Std.downcast(_open(cast type), Screen);
		
		// Move new screen to the bottom, under all global dialogs (and other elements if any)
		moveToBottom(currentScreen);
		return currentScreen;
	}

	// Any component with assetName set can be showed as a dialog, including screens
	public function openDialog(type:Class<Component>, ?global:Bool):Component
	{
		var dialog = _open(type);
		if (dialog == null)
		{
			return null;
		}
		
		dialogStack.push(dialog);
		if (!global)
		{
			localDialogs.push(dialog);
		}
		refreshChildrenEnabled();

		if (isClickingOnCurrentScreen)
		{
			isDialogJustOpened = true;
		}
		return dialog;
	}

	private function _open(type:Class<Component>):Component
	{
		if (type == null)
		{
			return null;
		}
		Log.debug('Open: $type');

		// Get or create
		var instance:Component = null;
		if (isReuseComponents)
		{
			// Reuse previous of same type
			var key = Type.getClassName(type);
			instance = pool[key];
			pool.remove(key);
			if (instance != null)
			{
				Log.debug(' Reuse: $instance');
			}
		}
		if (instance == null)
		{
			// Create new
			instance = createComponent(type);
		}
		if (instance.assetName == null)
		{
			Log.warn('For screens and dialogs ($instance) assetName shouldn\'t be null, ' +
			'as it would be nothing to display!');
		}

		// Add
		addChild(instance);
		Log.debug(' Opened: $instance');
		return instance;
	}

	// For both screens and dialogs
	// Normally, to close a dialog use Dialog.close(), because this _close() method 
	// doesn't dispatch Dialog.closeSignal.
//	@:allow(v7.lib.components.Dialog.close)
//	private function _close(instance:Component):Void
	public function close(instance:Component):Void
	{
		if (instance == null)
		{
			return;
		}
		Log.debug('Close: $instance');

		// Remove
		var isRemoved = false;
		if (instance == currentScreen)
		{
			currentScreen = null;
			currentScreenClass = null;
			isRemoved = true;
		}
		if (dialogStack.remove(instance))
		{
			isRemoved = true;
		}
		localDialogs.remove(instance);
		if (!isRemoved)
		{
			return;
		}
		refreshChildrenEnabled();

		// Put to pool for reusing
		if (isReuseComponents)
		{
			instance.parent.removeChild(instance);
			var className = Type.getClassName(Type.getClass(instance));
			if (!pool.exists(className))
			{
				pool[className] = instance;
				Log.debug(' Closed: $instance');
				return;
			}
		}
		// Dispose
		instance.dispose();
		Log.debug(' Closed: $instance and disposed');
	}

	// Implement isModal
	private function refreshChildrenEnabled():Void
	{
		// Disable all dialogs and screen under the toppest modal dialog.
		// Note: isModal should be set on Dialog initialization, because we don't 
		// have a signal for isModal changed.
		var isAnyModal = false;
		var len = dialogStack.length;
		for (i in 0...len)
		{
			var comp = dialogStack[len - 1 - i];
			comp.isEnabled = !isAnyModal;
			var dialog:Dialog = Std.downcast(comp, Dialog);
			if (dialog != null)
			{
				isAnyModal = isAnyModal || dialog.isModal;
			}
		}
		if (currentScreen != null)
		{
			currentScreen.isEnabled = !isAnyModal;
		}
	}

	// Implement isCloseOnClickOutside
	private function closeTopDialogsOnClickOutside(stageX:Float, stageY:Float):Void
	{
		// Close all dialogs with isCloseOnClickOutside=true beginning from the toppest 
		// until we meet a modal dialog (that would be the last closed dialog)
		var len = dialogStack.length;
		for (i in 0...len)
		{
			var comp = dialogStack[len - 1 - i];
			if (comp == null || comp.skin == null || comp.skin.parent == null)
			{
				continue;
			}

			// Check is clicked inside current dialog
			var isHit = comp.skin.hitTestPoint(stageX, stageY, true);
			if (isHit)
			{
				// Some dialog is hit and it covers all dialogs underneath, 
				// so don't close them
				break;
			}

			var dialog:Dialog = Std.downcast(comp, Dialog);
			// (Skip if not of Dialog type)
			if (dialog != null && dialog.skin != null && dialog.skin.parent != null)
			{
				if (!isHit && dialog.isCloseOnClickOutside)
				{
					dialog.close();
				}
				if (dialog.isModal)
				{
					// Modal dialog covers all dialogs underneath
					break;
				}
			}
		}
	}

	private function moveToBottom(component:Component):Void
	{
		if (component == null)
		{
			return;
		}
		if (component.skin != null)
		{
			component_readySignalHandler(component);
		}
		else
		{
			// Listeners
			component.readySignal.add(component_readySignalHandler);
		}
	}
	
	// Handlers

	private function skin_clickCapturedHandler(event:MouseEvent):Void
	{
		if (dialogStack.length <= 0)
		{
			return;
		}
		closeTopDialogsOnClickOutside(event.stageX, event.stageY);
	}

	private function component_readySignalHandler(component:v7.lib.components.Component):Void
	{
		// Listeners
		component.readySignal.remove(component_readySignalHandler);
		// moveToBottom
		if (component.skin != null && component.skin.parent != null)
		{
			component.skin.parent.addChildAt(component.skin, 0);
		}
	}
}
