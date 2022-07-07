package v1.framework;

import openfl.display.Sprite;
import openfl.events.Event;
import v1.framework.ui.Screen;
import v1.framework.ui.Screens;
import v1.framework.net.IProtocol;

/**
 * Application.
 * 
 */
class Application extends Sprite implements IBase
{
	// Settings

	private var startScreenClass:Class<Screen>;
	private var host:String;
	private var port:Int;

	// State

	// One application, one IoC.
	private var ioc(default, set):IoC;
	private function set_ioc(value:IoC):IoC
	{
		var ioc = this.ioc;
		if (ioc != value)
		{
			if (ioc != null)
			{
				// (To prevent calling set_ioc() again on ioc=null in dispose())
				this.ioc = null;
				// Dispose previous state
				dispose();
			}
			// Set
			this.ioc = ioc = value;
			if (ioc != null)
			{
				// Initialize
				init();
				// As application now can be created not only as Main class, 
				// but also by MultiApplication, it is possible for stage to be null.
				if (stage != null)
				{
					start();
				}
				else
				{
					// Listeners
					addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
				}
			}
		}
		return value;
	}
	
	private var protocol:IProtocol;
	private var screens:Screens;
	
	// For using in MultiApplication and StageResizer
	private var _stageWidth:Float = -1;
	@:isVar
	public var stageWidth(get, set):Float;
	public function get_stageWidth():Float
	{
		return _stageWidth <= 0 && stage != null ? stage.stageWidth : _stageWidth;
	}
	public function set_stageWidth(value:Float):Float
	{
		return _stageWidth = value;
	}

	private var _stageHeight:Float = -1;
	@:isVar
	public var stageHeight(get, set):Float;
	public function get_stageHeight():Float
	{
		return _stageHeight <= 0 && stage != null ? stage.stageHeight : _stageHeight;
	}
	public function set_stageHeight(value:Float):Float
	{
		return _stageHeight = value;
	}

	// Init

	public function new()
	{
		super();

		ioc = new IoC();
	}

	// Override to create some components, managers or other instances
	private function init():Void
	{
		// First of all set up IoC (register all class substitution, change defaultAssetName)
		configureApp();

		// Initialize IoC
		ioc.load();
		
		// Initialize managers
		var lang = ioc.getSingleton(LangManager);
		var audio = ioc.getSingleton(AudioManager);
		lang.load();
		audio.load();
	}

	// Override to call ioc.register() or change some settings
	private function configureApp():Void
	{
	}

	// Override to perform actions on added to stage
	private function start():Void
	{
	}
	
	// Override to free memory after changes made in all methods above and
	public function dispose():Void
	{
		// (That one should remove who added)
//-		if (parent != null)
//		{
//			parent.removeChild(this);
//		}
	}

	// Methods

	// Handlers

	private function addedToStageHandler(event:Event):Void
	{
		// (Somehow can be dispatched twice for app added to MultiApplication 
		// added to another MultiApplication, so remove after first dispatch.)
		// Listeners
		removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		
		start();
	}
}
