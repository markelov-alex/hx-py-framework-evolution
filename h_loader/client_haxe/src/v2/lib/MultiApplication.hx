package v2.lib;

import openfl.display.Stage;
import openfl.events.Event;
import v0.lib.util.Log;
import v1.lib.util.ArrayUtil;
import v2.lib.components.ResizeControl;

/**
 * MultiApplication.
 * 
 */
class MultiApplication extends Application
{
	// Settings
	
	private var defaultAppClass:Class<Application>;

	// State
	
	public var appCount(default, set):Int = 1;
	public function set_appCount(value:Int):Int
	{
		if (appCount != value)
		{
			appCount = value;
			refreshApps();
		}
		return value;
	}
	
	private var apps:Array<Application> = [];
	private var appMatrix:Array<Array<Application>>;
	private var resizeControl:ResizeControl;

	// Init

//	public function new()
//	{
//		super();
//	}

	override private function init():Void
	{
		super.init();
		
		resizeControl = ioc.create(ResizeControl);
		// Priority should be higher than for StageResizer to change Application's 
		// stageWidth/Height before they'll be used in StageResizer.
		resizeControl.priority = 3;
		resizeControl.skin = this;
		// Listeners
		resizeControl.resizeSignal.add(resizeControl_resizeSignalHandler);
	}

	override private function start():Void
	{
		super.start();

		refreshApps();
	}

	override public function dispose():Void
	{
		// Dispose all apps
		appCount = 0;
		
		resizeControl.dispose();
		
		super.dispose();
	}
	
	// Methods

	private function refreshApps():Void
	{
		var createCount = appCount - apps.length;
		if (createCount != 0)
		{
			Log.debug('Change appCount: ${apps.length} -> $appCount');
		}
		if (createCount == 0)
		{
			return;
		}
		// Create
		else if (createCount > 0)
		{
			for (i in 0...createCount)
			{
				var app = createApp(apps.length);
				apps.push(app);
			}
		}
		// Remove
		else
		{
			for (i in createCount...0)
			{
				var app = apps.pop();
				disposeApp(app);
			}
		}
		appMatrix = ArrayUtil.arrayToMatrix(apps);
		
		// Dispatch (to affect rearrangeApps() and all StageResizers)
		if (stage != null)
		{
			stage.dispatchEvent(new Event(Event.RESIZE));
		}
	}
	
	// Override to use index
	private function createApp(index:Int, ?appClass:Class<Application>, ?args:Array<Dynamic>):Application
	{
		if (appClass == null)
		{
			appClass = defaultAppClass;
		}
		if (args == null)
		{
			args = [];
		}
		
		Log.debug('Create application: $appClass');
		var app = Type.createInstance(appClass, args);
		addChild(app);
		return app;
	}
	
	private function disposeApp(app:Application):Void
	{
		if (app == null)
		{
			return;
		}
		Log.debug('Dispose application: $app');
		app.dispose();
		if (app.parent != null)
		{
			app.parent.removeChild(app);
		}
	}

	private function rearrangeApps():Void
	{
		if (appMatrix == null)
		{
			return;
		}
		
		// Rearrange
		var rowCount = appMatrix.length;
		var colCount = rowCount > 0 ? appMatrix[0].length : 0;
		var appWidth = colCount > 0 ? stageWidth / colCount : 0;
		var appHeight = rowCount > 0 ? stageHeight / rowCount : 0;
		for (i in 0...appMatrix.length)
		{
			var row = appMatrix[i];
			var y = i * appHeight;
			for (j in 0...row.length)
			{
				var app:Application = row[j];
				app.x = j * appWidth;
				app.y = y;
				app.stageWidth = appWidth;
				app.stageHeight = appHeight;
			}
		}
	}
	
	// Handlers

	private function resizeControl_resizeSignalHandler(stage:Stage):Void
	{
		rearrangeApps();
	}
}
