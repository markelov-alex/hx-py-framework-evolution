package v2.lib.components;

import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import v2.lib.components.Component;

/**
 * ModalControl.
 * 
 * Not used.
 * 
 * Fails when more than one used simultaneously.
 */
class ModalControl extends Component
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
				stage.removeEventListener(MouseEvent.CLICK, stage_clickCapturedHandler, true);
			}
			stage = value;
			if (stage != null)
			{
				// Listeners
				stage.addEventListener(MouseEvent.CLICK, stage_clickCapturedHandler, true);
			}
		}
		return value;
	}

	// Init

//	override private function init():Void
//	{
//		super.init();
//	}

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

	private function stage_clickCapturedHandler(event:MouseEvent):Void
	{
		if (!isEnabled || skin.parent == null)
		{
			return;
		}
		// Stops all clicks outside current skin
		// (but hand cursor is still showing over buttons)
		var clickPos = skin.parent.globalToLocal(new Point(event.stageX, event.stageY));
		if (!skin.hitTestPoint(clickPos.x, clickPos.y, true))
		{
			event.stopPropagation();
		}
	}
}
