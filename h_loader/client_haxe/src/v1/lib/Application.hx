package v1.lib;

import openfl.display.Sprite;
import openfl.events.Event;
import v0.lib.components.Screen;
import v0.lib.components.Screens;
import v0.lib.IoC;
import v0.lib.net.IProtocol;

/**
 * Application.
 * 
 */
class Application extends Sprite
{
	// Settings

	private var startScreenClass:Class<Screen>;
	private var host:String;
	private var port:Int;

	// State

	private var ioc:IoC;
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

		// As application now can be created not only as Main class, 
		// but also by MultiApplication, it is possible for stage to be null.
		if (stage != null)
		{
			init();
			start();
		}
		else
		{
			// Listeners
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
	}

	private function init():Void
	{
		ioc = IoC.getInstance();

		// First of all set up IoC (register all class substitution, change defaultAssetName)
		configureApp();
	}

	private function configureApp():Void
	{
	}
	
	public function dispose():Void
	{
		// (That one should remove who added)
//-		if (parent != null)
//		{
//			parent.removeChild(this);
//		}
	}

	// Methods
	
	private function start():Void
	{
	}

	// Handlers

	private function addedToStageHandler(event:Event):Void
	{
		// (Somehow can be dispatched twice for app added to multiapp 
		// added to another multiapp, so remove after first dispatch.)
		// Listeners
		removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		
		init();
		start();
	}
}
