package v1;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.events.DataEvent;
import openfl.events.ErrorEvent;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.XMLSocket;
import v0.lib.AudioManager;
import v0.lib.components.Screens;
import v0.lib.IoC;
import v0.lib.LangManager;
import v0.lib.Log;
import v1.coloring.ColoringModel.IColoringModel;
import v1.coloring.ColoringModel;
import v1.menu.MenuScreen;

/**
 * Main.
 * 
 * Changes:
 *  - add sockets.
 */
class Main extends Sprite
{
	// Settings
	
	private var host = "localhost";
	private var port = 5555;
	private var reconnectIntervalMs = 3000;
	
	// State
	
	private var socket:XMLSocket;
	
	// Init
	
	public function new()
	{
		super();

		// First of all register all class substitution
		var ioc = IoC.getInstance();
		ioc.register(IColoringModel, ColoringModel);
		
		ioc.load();
		LangManager.getInstance().load();
		AudioManager.getInstance().load();
		
		var screens = Screens.getInstance();
		screens.isReuseComponents = false;
		screens.skin = this;
		screens.open(MenuScreen);

		socket = ioc.getSingleton(XMLSocket);
		// Listeners
		socket.addEventListener(Event.CONNECT, socket_connectHandler);
		socket.addEventListener(Event.CLOSE, socket_closeHandler);
		socket.addEventListener(DataEvent.DATA, socket_dataHandler);
		socket.addEventListener(ProgressEvent.PROGRESS, socket_progressHandler);
		socket.addEventListener(ErrorEvent.ERROR, socket_errorHandler);
		socket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
		socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
		
		// Connect
		Log.debug('Connecting to ${this.host}:${this.port}...');
		socket.connect(host, port);
	}
	
	private function reconnectLater():Void
	{
		Timer.delay(function () {
			Log.debug('Reconnecting to ${this.host}:${this.port}...');
			socket.connect(host, port);
		}, reconnectIntervalMs);
	}

	// Handlers

	private function socket_connectHandler(event:Event):Void
	{
		Log.debug("CONNECTED");
	}

	private function socket_closeHandler(event:Event):Void
	{
		Log.debug('DISCONNECTED CLOSE');
		
		reconnectLater();
	}

	private function socket_dataHandler(event:DataEvent):Void
	{
		Log.debug('>> Data received: ${event.data}');
	}

	private function socket_progressHandler(event:ProgressEvent):Void
	{
		Log.info('Socket progress bytes: ${event.bytesLoaded} of ${event.bytesTotal}');
	}

	private function socket_errorHandler(event:ErrorEvent):Void
	{
		Log.error('Socket ERROR $event');
	}

	private function socket_ioErrorHandler(event:IOErrorEvent):Void
	{
		Log.error('Socket IO ERROR $event');
	}

	private function socket_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		Log.error('Socket SECURITY ERROR event: $event errorID: ${event.errorID}');

		// (Reconnect)
		reconnectLater();
	}
}
