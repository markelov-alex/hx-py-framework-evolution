package v6.lib.net.transport;

import openfl.events.ProgressEvent;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import v0.lib.Log;
import v5.lib.net.parser.BytesUtil;

/**
 * SocketTransport.
 * 
 */
class SocketTransport extends v5.lib.net.transport.SocketTransport
{
	// Settings
	
	// State
	
	private var tempOutputBytes = new ByteArray();

	// Init
	
//	public function new()
//	{
//		super();
//	}

//	public function new()
//	{
//		super();
//	}

	// Methods

	override public function send(plainData:Dynamic):Void
	{
		if (isBinary)
		{
			// Add length field to given bytes
			var dataBytes:ByteArray = Std.downcast(plainData, ByteArrayData);
			if (dataBytes != null && dataBytes.length != 0)
			{
				tempOutputBytes.clear();
				// (Endian is big by default and not changing)
				//tempOutputBytes.endian = Endian.BIG_ENDIAN;
				BytesUtil.writeInt(tempOutputBytes, dataBytes.length, 2);
				tempOutputBytes.writeBytes(dataBytes);
				plainData = tempOutputBytes;
			}
		}
		super.send(plainData);
	}

	// Handlers

	override private function socket_socketDataHandler(event:ProgressEvent):Void
	{
		Log.debug('Prev data buffer: ${BytesUtil.toHex(inputBuffer)} position: ${inputBuffer.position}');
		if (!isBinary)
		{
			Log.debug(' (Prev data buffer as utf: ${BytesUtil.toUTF(inputBuffer)})');
		}
		// Read (inputBuffer can contain unparsed bytes after previous iterations)
		socket.readBytes(inputBuffer, inputBuffer.length, socket.bytesAvailable);
		Log.debug('>> Current data buffer: ${BytesUtil.toHex(inputBuffer)}');
		if (!isBinary)
		{
			Log.debug(' (Current data buffer as utf: ${BytesUtil.toUTF(inputBuffer)})');
		}

		// Parse
		inputBuffer.endian = socket.endian;
		inputBuffer.position = 0;

		var delimiter = 0; // const
		var bufferLength:Int = (inputBuffer.length:Int);
		var itemStart:Int = inputBuffer.position;
		while ((inputBuffer.position:Int) < bufferLength)
		{
			if (isBinary)
			{
				// Split bytes on items, using first 2 bytes of each item as item length
				var minLength = 2; // Length field is 2 bytes long
				var bufferLeft:Int = bufferLength - inputBuffer.position;
				if (bufferLeft < minLength)
				{
					// Not enough bytes even for reading length field (wait for more bytes)
					Log.debug('Not enough bytes in buffer: $bufferLeft to read length header: $minLength. ' +
					'Wait for more bytes...');
					break;
				}

				// Read 2 bytes
				inputBuffer.endian = Endian.BIG_ENDIAN;
				var length = BytesUtil.readInt(inputBuffer, 2);
				var itemEnd:Int = inputBuffer.position + length;
				if (itemEnd > bufferLength)
				{
					// Leave last bytes unparsed as they are not yet complete
					Log.debug('The end of the message is not yet received ($itemEnd > $bufferLength). ' +
						'Wait for more bytes...');
					break;
				}

				// Read length bytes
				inputBuffer2.clear();
				// (Doesn't change inputBuffer's position, so use readBytes())
				//inputBuffer2.writeBytes(inputBuffer, inputBuffer.position, length);
				inputBuffer.readBytes(inputBuffer2, 0, length);
				// Note: Set position=0 in handlers, because signal could have more than 
				// one listener, and we cannot reset position for each listener.
				//inputBuffer2.position = 0;

				Log.debug('(temp Bin)   Data returned: ${BytesUtil.toHex(inputBuffer2)}');
				// Dispatch
				receiveDataSignal.dispatch(inputBuffer2);
				Log.debug('(temp Bin)   The rest of data buffer: ${BytesUtil.toHex(inputBuffer, inputBuffer.position)}');

				// Start new item
				itemStart = inputBuffer.position;
			}
			else
			{
				var byte = inputBuffer.readByte();
				// Check item end
				if (byte == delimiter)
				{
					// Read item
					var pos = inputBuffer.position;
					inputBuffer.position = itemStart;
					var data = inputBuffer.readUTFBytes(pos - itemStart);

					Log.debug('(temp Str)   Data returned: $data');
					Log.debug('(temp Str)   The rest of data buffer: ${BytesUtil.toHex(inputBuffer, inputBuffer.position)}');
					// Dispatch
					receiveDataSignal.dispatch(data);

					// Start new item
					itemStart = inputBuffer.position;
				}
			}
		}
		inputBuffer.position = itemStart;

		// Clear bytes that were read
		if (inputBuffer.position >= inputBuffer.length)
		{
			Log.debug(' All parsed data will be cleared: ${BytesUtil.toHex(inputBuffer)}');
			// Whole buffer was parsed
			inputBuffer.clear();
		}
		else if (inputBuffer.position > 0)
		{
			// Some data left unparsed 
			// (Clear parsed data (before current position) 
			// and leave unparsed data (after position) in buffer)
			inputBuffer2.clear();
			Log.debug(' Parsed data to be cleared: ${BytesUtil.toHex(inputBuffer, 0, inputBuffer.position)}');
			inputBuffer2.writeBytes(inputBuffer, inputBuffer.position);
			var temp = inputBuffer2;
			inputBuffer2 = inputBuffer;
			inputBuffer = temp;
			Log.debug(' Unparsed data: ${BytesUtil.toHex(inputBuffer)}');
		}
		else
		{
			Log.debug(' All data is unparsed: ${BytesUtil.toHex(inputBuffer)}');
		}
	}
}
