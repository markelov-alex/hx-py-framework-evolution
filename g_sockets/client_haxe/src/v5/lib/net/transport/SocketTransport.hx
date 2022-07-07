package v5.lib.net.transport;

import openfl.events.ProgressEvent;
import v0.lib.Log;

/**
 * SocketTransport.
 * 
 * Can work in both binary and UTF mode.
 */
class SocketTransport extends BinarySocketTransport
{
	// Settings
	
	public var isBinary = false;

	// State

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override public function send(plainData:Dynamic):Void
	{
		if (isBinary)
		{
			super.send(plainData);
		}
		else
		{
			socket.writeUTFBytes(Std.string(plainData));
			socket.writeByte(0);
			socket.flush();
		}
	}

	// Handlers

	override private function socket_socketDataHandler(event:ProgressEvent):Void
	{
		if (isBinary)
		{
			super.socket_socketDataHandler(event);
		}
		else
		{
			#if !js
			var bytesAvailable = socket.bytesAvailable;
			var byte, data;
			var delimiter = 0; // const
			for (i in 0...bytesAvailable)
			{
				byte = socket.readByte();
				inputBuffer.writeByte(byte);
	
				if (byte == delimiter)
				{
					inputBuffer.endian = socket.endian;
					inputBuffer.position = 0;
					data = inputBuffer.readUTFBytes(inputBuffer.bytesAvailable);
					inputBuffer.position = 0;
					inputBuffer.length = 0;
					Log.debug('>> Data received: $data');
	
					// Dispatch
					receiveDataSignal.dispatch(data);
				}
			}
			#else
			// Dispatch
			receiveDataSignal.dispatch(socket.readUTFBytes(socket.bytesAvailable));
			#end
		}
	}
}
