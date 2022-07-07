package v1.dresser;

import v1.dresser.DresserModel;

/**
 * DresserScreen.
 * 
 */
class DresserScreen extends v0.dresser.DresserScreen
{
	// Settings

	// State

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override private function assignSkin():Void
	{
		// Temp to neutralize super.assignSkin()
		var model:DresserModel = Std.downcast(ioc.getSingleton(DresserModel), DresserModel);
		savedState = model.state;
		
		super.assignSkin();
	}

	override private function unassignSkin():Void
	{
		super.unassignSkin();
		
		// Temp to neutralize super.unassignSkin()
		savedState = null;
	}
}
