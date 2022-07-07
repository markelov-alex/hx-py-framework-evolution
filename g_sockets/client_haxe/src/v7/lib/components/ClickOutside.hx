package v7.lib.components;

import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;

/**
 * ClickOutside.
 * 
 * Not used.
 */
class ClickOutside extends Component
{
	// Settings

	// State
	
	public var stage(default, set):Stage;
	public function set_stage(value:Stage):Stage
	{
		if (stage != value)
		{
			if (stage != null)
			{
				// Listeners
				stage.removeEventListener(MouseEvent.CLICK, stage_clickHandler);
			}
			stage = value;
			if (stage != null)
			{
				// Listeners
				stage.addEventListener(MouseEvent.CLICK, stage_clickHandler);
			}
		}
		return value;
	}
	
	// Needed to skip the first click, by which current component was actually created
	private var skipCount = 1;
	// Needed to know whether click was inside (true) or outside (false) the skin
	private var isSkinClicked = false;

	// Signals

	public var clickOutsideSignal(default, null) = new Signal<ClickOutside>();

	// Init

//	public function new()
//	{
//		super();
//	}

	override public function dispose():Void
	{
		clickOutsideSignal.dispose();

		super.dispose();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		stage = skin.stage;
		// (Reset, if the component will be reused sometime)
		skipCount = 1;
		
		// Listeners
		skin.addEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
		skin.addEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);
		skin.addEventListener(MouseEvent.CLICK, skin_clickHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
		skin.removeEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);
		skin.removeEventListener(MouseEvent.CLICK, skin_clickHandler);

		stage = null;

		super.unassignSkin();
	}

	// Handlers

	private function skin_addedToStageHandler(event:Event):Void
	{
		stage = skin.stage;
	}

	private function skin_removedFromStageHandler(event:Event):Void
	{
		stage = null;
	}

	// Called only if clicked on skin
	private function skin_clickHandler(event:MouseEvent):Void
	{
		if (!isEnabled)
		{
			return;
		}
		// Prevent stage_clickHandler() calling
		isSkinClicked = true;
	}

	// Called on every click
	private function stage_clickHandler(event:MouseEvent):Void
	{
		if (isSkinClicked)
		{
			// Clicked inside
			isSkinClicked = false;
			return;
		}
		if (skipCount > 0)
		{
			skipCount--;
			// Skip same click that initiated current component creation
			return;
		}
		if (!isEnabled)
		{
			return;
		}
		// Dispatch
		clickOutsideSignal.dispatch(this);
	}
}
