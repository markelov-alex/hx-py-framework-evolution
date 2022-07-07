package v9.net;

import v7.lib.util.Log;

/**
 * CustomProtocol2.
 * 
 * CustomProtocol with buffering sending messages to send them before version message. 
 * This is to help testing version switching.
 */
class CustomProtocol2 extends CustomProtocol
{
	// Settings
	
	public var minPlainDataBufferLength = 1;

	// State
	
	private var plainDataBuffer:Array<Dynamic> = [];

	// Init

//	public function new()
//	{
//		super();
//	}

	// Methods

	override public function send(plainData:Dynamic):Void
	{
		// Check is a version
		if (multiParser != null && Std.isOfType(plainData, String) && 
			multiParser.parserByVersion.exists(plainData))
		{
			// PlainData is a version
			flushPlainDataBuffer();
			super.send(plainData);
		}
		else if (isConnected)
		{
			// PlainData is not a version
			Log.debug(' (Add to send-later-buffer: $plainData)');
			plainDataBuffer.push(plainData);
			var leaveInBuffer = minPlainDataBufferLength;
			var sendCount = plainDataBuffer.length - leaveInBuffer;
			flushPlainDataBuffer(sendCount > 0 ? sendCount : 0);
		}
	}

	private function flushPlainDataBuffer(sendCount:Int=-1):Void
	{
		// Send previous
		var sendDataArray = sendCount < 0 ? plainDataBuffer : plainDataBuffer.slice(0, sendCount);
		plainDataBuffer = sendCount < 0 ? [] : plainDataBuffer.slice(sendCount);
		if (sendDataArray.length > 0 || plainDataBuffer.length > 0)
		{
			Log.debug(' (Flush send-later-buffer send: $sendDataArray leave: $plainDataBuffer)');
		}
		for (pd in sendDataArray)
		{
			super.send(pd);
		}
	}
}
