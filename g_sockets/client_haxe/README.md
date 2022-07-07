# Sockets

1. Simple XMLSocket using
2. Simple Protocol
3. Finished Protocol, Parser (todo make dresser with binary protocol)
4. Use lists instead of dicts as more compact protocol. 
5. Binary protocol (use Socket in UTFSocketTransport instead of XMLSocket).
6. Switching between different versions of protocol
   (MultiParser with ability to change Parser).
7. Controller (replace protocol, as socket-only solution, with controller — game logic with or without sockets.)
   To parse commands only once move parser from protocol to transport (bad way) or use one protocol for one parser and multiple controllers for that protocol (good way).

(8. View commands - bad idea: protocol would be not fixed in Protocol, but spread across components)

For v6:
Possible implementations:
1. Change version by command — from outside of parser. To do so we should execute each command just after it was parsed, and only then parse the next one. Otherwise, some commands will be parsed with wrong parser. This approach is expensive as it's much better to parse whole bunch of commands and only then to execute them, then switching between parsing and executing every time.
2. So, it's better to introduce switching versions inside parsers. All traffic can be divided on series of messages. Each message can carry multiple commands. Also one message can encode only 1 version name, which would mean version switching. Parser process message by message, and when version message received, parser changed, and further parsing continues already with another parser.

Messages themselves encoded same way for all protocols. The only difference is between binary and string protocols. For binary protocol first 2 bytes encode a message size to be parsed next. That's how boundaries between messages can be found. For string protocol messages messages separated from each other by zero-byte (\x00), as it doesn't encode any character and so cannot be muddled.

In client separating messages is delegated to Transport, on server — all raw data goes straight to Parser. That's mostly because of different bytes classes on Haxe/OpenFl and Python. OpenFl's ByteArray encapsulate current position cursor, while Python's bytes as treated same like regular strings, and analogue for current position cursor should be implemented by ourselves in Parser and Server (unparsed_bytes) classes. (Or something like that.)

v8
To test that versions switched alright, we send version data just after some other data. (Now it's not working and v9 is to fix that.) To send some data before version data send-later-buffer is used. Press Numpad_Plus to increase send-later-buffer, and Numpad_Minus to decrease it. 


todo (if needed) encode version in same way (start with "v.", end with \x00) for binary and string protocols and for binary protocols use letter "b" on the end for binary protocols. So, we would know at least where to find next version data (Transport.isInputBinary would get switched by this "b" marker).
