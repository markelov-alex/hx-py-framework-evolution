package v1.dresser;

/**
 * Dresser.
 * 
 * Main component implementing dressing games functionality.
 */
class Dresser extends v0.dresser.Dresser
{
	// Settings

	// State

	private var model:DresserModel;
	
	// Init

	public function new()
	{
		super();

		model = ioc.getSingleton(DresserModel);
		// Listeners
		model.stateChangeSignal.add(model_stateChangeSignalHandler);
		model.itemChangeSignal.add(model_itemChangeSignalHandler);
	}

	override public function dispose():Void
	{
		super.dispose();

		if (model != null)
		{
			// Listeners
			model.stateChangeSignal.remove(model_stateChangeSignalHandler);
			model.itemChangeSignal.remove(model_itemChangeSignalHandler);
			model = null;
		}
	}

	// Methods

	override private function assignSkin():Void
	{
		super.assignSkin();
		
		state = model.state;
	}

	override private function switchItem(index:Int, step:Int=1):Void
	{
		// Refresh model
		var item = items[index];
		if (item != null)
		{
			var value = (item.currentFrame + step) % item.totalFrames;
			value = value < 1 ? item.totalFrames - value : value;
			model.changeItem(index, value);
		}
	}
	
	// Handlers

	private function model_stateChangeSignalHandler(value:Array<Int>):Void
	{
		// Refresh skin
		state = value;
	}

	private function model_itemChangeSignalHandler(index:Int, value:Int):Void
	{
		var item = items[index];
		if (item != null)
		{
			item.gotoAndStop(value);
		}
	}
}
