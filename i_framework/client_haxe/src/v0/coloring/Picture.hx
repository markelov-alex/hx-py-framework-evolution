package v0.coloring;

import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.events.MouseEvent;
import openfl.geom.ColorTransform;
import v0.coloring.IColoringController;
import v0.coloring.IColoringModel;
import v0.lib.components.Component;

/**
 * Picture.
 * 
 */
class Picture extends Component
{
	// Settings
	
	// State

	private var model:IColoringModel;
	private var controller:IColoringController;

	private var pictureItems:Array<MovieClip> = [];

	public var pictureState(get, set):Array<Int>;
	public function get_pictureState():Array<Int>
	{
		return [for (item in pictureItems) item.transform.colorTransform.color];
	}
	public function set_pictureState(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		var len = value.length;
		for (i => item in pictureItems)
		{
			// (Note: value = []; value[1] == 0;)
			var v = i < len ? value[i] : -1;
			if (item != null)
			{
				applyColor(item, v);
			}
		}
		return value;
	}

	// Init

	override private function init():Void
	{
		super.init();

		// Skin set directly by Coloring
		skinPath = null;
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();

		model = ioc.getSingleton(IColoringModel);
		controller = ioc.getSingleton(IColoringController);
		
		if (mc != null)
		{
			pictureItems = [];
			parsePictureItems(mc, pictureItems);
			for (item in pictureItems)
			{
				applyColor(item, model.defaultColor);
				// Listeners
				item.addEventListener(MouseEvent.CLICK, pictureItem_clickSignalHandler);
			}
		}

		// Note: Add listeners after all subcomponents prepared
		// Listeners
		model.currentPictureStateChangeSignal.add(model_currentPictureStateChangeSignalHandler);
		controller.applyColorSignal.add(controller_applyColorSignalHandler);

		// Apply
		pictureState = model.currentPictureState;
	}

	override private function unassignSkin():Void
	{
		for (item in pictureItems)
		{
			// Listeners
			item.removeEventListener(MouseEvent.CLICK, pictureItem_clickSignalHandler);
		}
		pictureItems = [];

		// Listeners
		model.currentPictureStateChangeSignal.remove(model_currentPictureStateChangeSignalHandler);
		controller.applyColorSignal.remove(controller_applyColorSignalHandler);
		model = null;
		controller = null;
		
		super.unassignSkin();
	}

	/**
	 * Find recursively all movie clips without other movie clips inside.
	 */
	private function parsePictureItems(picture:MovieClip, pictureItems:Array<MovieClip>):Void
	{
		var mcCount = 0;
		for (i in 0...picture.numChildren)
		{
			var item = Std.downcast(picture.getChildAt(i), MovieClip);
			if (item != null)
			{
				mcCount++;
				parsePictureItems(item, pictureItems);
			}
		}
		if (mcCount == 0)
		{
			pictureItems.push(picture);
		}
	}

	private function applyColor(object:DisplayObject, color:Int=-1):Void
	{
		if (object != null)
		{
			if (color <= 0)
			{
				color = model.defaultColor;
			}
			var ct = new ColorTransform();
			ct.color = color;
			object.transform.colorTransform = ct;
		}
	}
	
	// Handlers

	private function model_currentPictureStateChangeSignalHandler(value:Array<Int>):Void
	{
		// Refresh skin
		pictureState = model.currentPictureState;
	}

	private function pictureItem_clickSignalHandler(event:MouseEvent):Void
	{
		var itemIndex = pictureItems.indexOf(event.currentTarget);
		controller.applyColor(itemIndex, model.color);
	}

	private function controller_applyColorSignalHandler(itemIndex:Int, color:Int):Void
	{
		applyColor(pictureItems[itemIndex], color);
	}
}
