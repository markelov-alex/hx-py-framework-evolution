package v1.lib.components;

import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import v0.lib.components.Button;
import v0.lib.components.Component;
import v0.lib.components.Resizer.AlignH;
import v0.lib.components.Resizer.AlignV;
import v0.lib.components.Resizer.ResizeMode;
import v0.lib.components.Resizer.StageResizer;
import v0.lib.Signal;

/**
 * Dialog.
 * 
 */
class Dialog extends Component
{
	// Settings
	
	public var closeButtonPath:String = "closeButton";
	public var clickOutsidePath:String = "";
	public var modalControlPath:String = "";
	public var modalPath:String = "modal";
	
	public var isCloseOnClickOutside(default, set):Bool = false;
	public function set_isCloseOnClickOutside(value:Bool):Bool
	{
		if (clickOutside != null)
		{
			clickOutside.isEnabled = value;
		}
		return isCloseOnClickOutside = value;
	}

	public var isModal(default, set):Bool;
	public function set_isModal(value:Bool):Bool
	{
		// Stops click events, but hand cursor over buttons is still appeared, 
		// so implement madality in Screens using Component's isEnabled and 
		// adding isParentEnabled (to do in v2)
		if (modalControl != null)
		{
			modalControl.isEnabled = value;
		}
		if (modal != null)
		{
			// (Doesn't work for unknown reason, so make visible=false)
			modal.mouseEnabled = value;
			modal.mouseChildren = value;
			// Uncomment if mouseEnabled doesn't work
			modal.visible = value;
		}
		return isModal = value;
	}

	// State

	private var screens:Screens;
	
	private var closeButton:Button;
	private var resizer:StageResizer;
	private var clickOutside:ClickOutside;
	private var modalControl:ModalControl;
	
	private var modal:DisplayObjectContainer;
	
	// Signals
	
	public var closeSignal(default, null) = new Signal<Dialog>();

	// Init

	public function new()
	{
		super();

		screens = Std.downcast(v0.lib.components.Screens.getInstance(), Screens);

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

		clickOutside = createComponent(ClickOutside);
		clickOutside.skinPath = clickOutsidePath;
		clickOutside.isEnabled = isCloseOnClickOutside;
		// Listeners
		clickOutside.clickOutsideSignal.add(clickOutside_clickOutsideSignalHandler);
		addChild(clickOutside);

		modalControl = createComponent(ModalControl);
		modalControl.skinPath = modalControlPath;
		modalControl.isEnabled = isModal;
		addChild(modalControl);
	}

	override public function dispose():Void
	{
		super.dispose();

		closeSignal.dispose();
		
		screens = null;
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		modal = Std.downcast(resolveSkinPath(modalPath), DisplayObjectContainer);
		
		if (modal != null)
		{
			// (Doesn't work for unknown reason, so make visible=false)
			modal.mouseEnabled = isModal;
			modal.mouseChildren = isModal;
			// Uncomment if mouseEnabled doesn't work
			modal.visible = isModal;
		}
		
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
		
		super.unassignSkin();
	}

	public function close():Void
	{
		// Dispatch
		closeSignal.dispatch(this);
		
		if (screens != null)
		{
			screens.close(this);
		}
	}

	// Handlers

	private function closeButton_clickSignalHandler(target:Button):Void
	{
		close();
	}

	private function clickOutside_clickOutsideSignalHandler(target:ClickOutside):Void
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
