package v7.lib.components;

import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import v7.lib.components.Resizer.AlignH;
import v7.lib.components.Resizer.AlignV;
import v7.lib.components.Resizer.ResizeMode;
import v7.lib.components.Resizer.StageResizer;
import v7.lib.util.Signal;

/**
 * Dialog.
 * 
 * Note: For Screens, Dialog is just a regular component with 
 * isCloseOnClickOutside and isModal properties.
 * 
 * For user's convenience, closeButton and resizer is added, 
 * plus using modal background movie clip with isModal property. 
 */
class Dialog extends Component
{
	// Settings
	
	public var closeButtonPath:String = "closeButton";
	public var modalPath:String = "modal";

	public var isModal(default, set):Bool;
	public function set_isModal(value:Bool):Bool
	{
		if (isModal != value)
		{
			isModal = value;
			refreshModal();
		}
		return value;
	}

	public var isCloseOnClickOutside:Bool = false;

	// State

	private var screens:Screens;
	
	private var closeButton:Button;
	private var resizer:StageResizer;
	
	private var modal:DisplayObjectContainer;
	private var modalParent:DisplayObjectContainer;
	
	// Signals
	
	// Only if closed by some user action (on any dialog.close() called).
	// Not dispatched if closed on screen switched.
	public var closeSignal(default, null) = new Signal<Dialog>();

	// Init

	public function new()
	{
		super();

		screens = Screens.getInstance();

		closeButton = createComponent(Button);
		closeButton.skinPath = closeButtonPath;
		// Listeners
		closeButton.clickSignal.add(closeButton_clickSignalHandler);
		addChild(closeButton);

		resizer = createComponent(StageResizer);
		resizer.resizeMode = ResizeMode.FIT_MIN;
		resizer.alignH = AlignH.CENTER;
		resizer.alignV = AlignV.CENTER;
		resizer.stretchBackgroundPath = modalPath;
		addChild(resizer);
	}

	override public function dispose():Void
	{
		super.dispose();

		closeSignal.dispose();
		
		screens = null;
	}

	private var _className:String;
	public function toString():String
	{
		if (_className == null)
		{
			_className = Type.getClassName(Type.getClass(this));
		}
		var modal = isModal ? " modal" : "";
		var outside = isCloseOnClickOutside ? " closeOnClickOutside" : "";
		return '[$_className$modal$outside]';
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		modal = Std.downcast(resolveSkinPath(modalPath), DisplayObjectContainer);

		refreshModal();
		
		// Listeners
		if (modal != null)
		{
			modal.addEventListener(MouseEvent.CLICK, modal_clickHandler);
		}
	}

	override private function unassignSkin():Void
	{
		// Listeners
		if (modal != null)
		{
			modal.removeEventListener(MouseEvent.CLICK, modal_clickHandler);
		}
		
		modal = null;
		modalParent = null;
		
		super.unassignSkin();
	}

	/**
	 * Usually called on:
  	 *  - close and other buttons clicked, 
  	 *  - click outside the skin (if isCloseOnClickOutside==true).
  	 * To close a dialog without calling this method, use screens.close(dialog) directly.
  	 * Override if you want to cancel normal dialog closing on some condition. 
  	 * For example, to show ConfirmDialog.
	 */
	public function close():Void
	{
		// Dispatch
		closeSignal.dispatch(this);

		if (screens != null)
		{
			screens.close(this);
		}
	}

	private function refreshModal():Void
	{
		if (modal != null)
		{
			// Temporarily remove from display list to 
			// avoid hitTestPoint() == true in Screens
			if (!isModal && modal.parent != null)
			{
				modalParent = modal.parent;
				modalParent.removeChild(modal);
			}
			else if (isModal && modalParent != null)
			{
				modalParent.addChild(modal);
			}
		}
	}

	// Handlers

	private function closeButton_clickSignalHandler(target:Button):Void
	{
		close();
	}

	private function modal_clickHandler(event:MouseEvent):Void
	{
		if (isCloseOnClickOutside)
		{
			close();
		}
	}
}
