package v0.lib.components;

import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import v0.lib.util.Signal;
import v0.lib.components.Component;

/**
 * KeyControl.
 * 
 * Simple way to get keyUp and keyDown events from any DisplayObject on the stage.
 */
class KeyControl extends Component
{
	// Settings

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
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
				stage.removeEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
			}
			
			this.stage = stage = value;
			
			if (stage != null)
			{
				// Listeners
				stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
				stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
			}
		}
		return value;
	}
	
	// Signals
	
	public var keyDownSignal(default, null) = new Signal<KeyboardEvent>();
	public var keyUpSignal(default, null) = new Signal<KeyboardEvent>();

	// Init

//	public function new()
//	{
//		super();
//	}

	override public function dispose():Void
	{
		keyDownSignal.dispose();
		keyUpSignal.dispose();
		
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

	private function stage_keyDownHandler(event:KeyboardEvent):Void
	{
		// Dispatch
		keyDownSignal.dispatch(event);
	}

	private function stage_keyUpHandler(event:KeyboardEvent):Void
	{
		// Dispatch
		keyUpSignal.dispatch(event);
	}
}
