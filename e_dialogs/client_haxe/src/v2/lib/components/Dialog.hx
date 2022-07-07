package v2.lib.components;

import v0.lib.Log;
import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import v0.lib.components.Resizer.AlignH;
import v0.lib.components.Resizer.AlignV;
import v0.lib.components.Resizer.ResizeMode;
import v0.lib.components.Resizer.StageResizer;
import v0.lib.Signal;
import v2.lib.components.Button;
import v2.lib.components.Component;

/**
 * Dialog.
 * 
 * Changes:
 *  - Component version,
 *  - remove ModalControl, as buttons are still with hand cursor on mouse over, 
 *  though not clickable. Besides it breaks other dialogs over current paralizing 
 *  all work, because all clicks are intercepted by ModalControl. So, it eather way 
 *  should be disabled with his dialog too. That's why modality implementation 
 *  moved to Screens (by using isEnabled and isParentEnabled),
 *  - remove ClickOuside, because it works bad when more than one dialog is opened; 
 *  to coordinate multiple click-outside functionalities we centralize it in Screens. 
 *  
 * Note: After modality and close-on-click-outside functionalities were moved to Screens, 
 * it's possible to create IDialog interface with isCloseOnClickOutside and isMadal 
 * fields and use any component as a normal full-featured dialog, and Dialog class 
 * would be just a helper. (But it's not really needed, so we'll just use Dialog.)
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
			// (Doesn't work for unknown reason, so make visible=false)
//			modal.mouseEnabled = isModal;
//			modal.mouseChildren = isModal;
			// (Uncomment if mouseEnabled doesn't work)
			// (Doesn't work for hitTestPoint(), so remove from display list)
//			modal.visible = isModal;
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
		Log.debug('## $this Click on closeButton -> close');
		close();
	}

	private function modal_clickHandler(event:MouseEvent):Void
	{
		if (isCloseOnClickOutside)
		{
			Log.debug('## $this Click on Modal -> close');
			close();
		}
		else
		{
			Log.debug('## $this Click on Modal -> close (isCloseOnClickOutside==false -> skip)');
		}
	}
}
