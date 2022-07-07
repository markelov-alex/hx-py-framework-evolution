package v1.framework.ui.controls;

import openfl.display.Stage;
import openfl.events.Event;
import v1.framework.ui.Component;
import v1.framework.util.Signal;

/**
 * ResizeControl.
 * 
 * Simple way to listen Resize event from any DisplayObject on the stage.
 */
class ResizeControl extends Component
{
	// Settings
	
	public var priority = 0;

	// State

	public var stage(default, set):Stage;
	public function set_stage(value:Stage):Stage
	{
		var stage = this.stage;
		if (stage != value)
		{
			if (stage != null)
			{
				// Listeners
				stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
			}
			
			this.stage = stage = value;
			
			if (stage != null)
			{
				// Listeners
				stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, priority);
			}
		}
		return value;
	}
	
	// Signals
	
	public var resizeSignal(default, null) = new Signal<Stage>();

	// Init

//	override private function init():Void
//	{
//		super.init();
//	}

	override public function dispose():Void
	{
		resizeSignal.dispose();

		super.dispose();
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		stage = skin.stage;
		
		// Listeners
		skin.addEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
		skin.addEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);
	}

	override private function unassignSkin():Void
	{
		// Listeners
		skin.removeEventListener(Event.ADDED_TO_STAGE, skin_addedToStageHandler);
		skin.removeEventListener(Event.REMOVED_FROM_STAGE, skin_removedFromStageHandler);
		
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

	private function stage_resizeHandler(event:Event):Void
	{
		// Dispatch
		resizeSignal.dispatch(stage);
	}
}
