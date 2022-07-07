package v1.app.net;

import v1.framework.net.Protocol;
import v1.framework.util.Log;

/**
 * Protocol2.
 * 
 * Send-later-buffer added. For testing protocol version switching.
 */
class Protocol2 extends Protocol
{
	// Settings

	public var minPlainDataBufferLength = 0;
	private var autoChangeVersionOnCount = 3;

	// State

	private var plainDataBuffer:Array<Dynamic> = [];
	private var sendCount = 0;

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
			if (minPlainDataBufferLength > 0)
			{
				Log.debug(' (Add to send-later-buffer: $plainData)');
			}
			plainDataBuffer.push(plainData);
			var leaveInBuffer = minPlainDataBufferLength;
			var sendCount = plainDataBuffer.length - leaveInBuffer;
			flushPlainDataBuffer(sendCount > 0 ? sendCount : 0);
			
			// Auto change version
			this.sendCount++;
			if (multiParser != null && this.sendCount >= autoChangeVersionOnCount)
			{
				this.sendCount = 0;
				var versions = multiParser.versions;
				var nextVersion;
				var isRandom = true;
				if (isRandom)
				{
					var nextIndex = Math.floor(Math.random() * versions.length);
					nextVersion = versions[nextIndex];
				}
				else
				{
					var index = versions.indexOf(this.version);
					var nextIndex = index + 1 >= versions.length ? 0 : index + 1;
					nextVersion = versions[nextIndex];
				}
				Log.debug('AUTO change version: ${this.version} -> $nextVersion for testing needs.');
				send(nextVersion);
			}
		}
	}

	private function flushPlainDataBuffer(sendCount:Int=-1):Void
	{
		// Send previous
		var sendDataArray = sendCount < 0 ? plainDataBuffer : plainDataBuffer.slice(0, sendCount);
		plainDataBuffer = sendCount < 0 ? [] : plainDataBuffer.slice(sendCount);
		if ((sendDataArray.length > 0 || plainDataBuffer.length > 0) && minPlainDataBufferLength > 0)
		{
			Log.debug(' (Flush send-later-buffer send: $sendDataArray leave: $plainDataBuffer)');
		}
		for (pd in sendDataArray)
		{
			super.send(pd);
		}
	}
}
