# Эволюция игрового фреймворка. Клиент 22. Сокет-клиент

Использование HTTP-запросов имеет один существенный недостаток. Сообщение не может быть послано по инициативе сервера. Клиент может получить сообщение от сервера только в виде ответа на собственный запрос. Поэтому данный способ обмена данными хорош только для одиночной игры, когда есть только один источник событий — пользователь. В данном случае все события сервера предсказуемы, и сервер может заранее сказать клиенту, когда ему нужно сделать следующий запрос.

Но уже, например, для такой простой игры как шашки требуется решение получше. Чтобы узнать, походил ли соперник, приходится либо бомбардировать сервер периодическими запросами, либо делать long polling запрос (техника [Comet](https://en.wikipedia.org/wiki/Comet_(programming))), который ждет совершения события и возвращает ответ только тогда, когда есть что возвращать. Первый способ можно сравнить с DoS-атакой (Deny of Service), а второй требует множества одновременных соединений для HTTP-сервера. При этом на сервере придется тратить дополнительные ресурсы на периодическую проверку БД (обычно, Redis) на предмет совершения хода другим игроком.

Оба решения непрактичны и в реальности не применяются, ведь гораздо проще и удобнее сделать сразу все на сокетах (sockets). Тем более что сам HTTP построен поверх сокетов. Только в HTTP соединение закрывается сразу после отправки сообщения, а при непосредственном использовании сокетов мы сами решаем, когда отправлять сообщения и когда закрывать подключение. И благодаря тому, что не нужно устанавливать новое соединение при каждой отправке запроса, данные доходят максимально быстро.

Что же такое сокеты? В общем случае Socket (англ. разъём) — это программный интерфейс для обеспечения обмена данными между процессами. Эти процессы могут быть запущены как на одной машине, так и на разных, если они соединены в сеть. Можно использовать сокеты даже в рамках одного приложения, между разными его процессами, но на этот случай есть механизмы и побыстрее (pipes).

В данном материале нас будут интересовать сетевые сокеты (Network socket), которые благодаря тому, что они чаще всего используются с интернет-протоколом (Internet Protocol, IP), обычно называются интернет-сокетами (Internet socket).

Все машины (а точнее операционные системы (ОС)), подключенные к Интернету, имеют свой IP-адрес по которому их можно различать в сети. Внутри системы каждое запущенное приложение (процесс) может иметь один или несколько портов — адресов процесса внутри системы. При создании сокета ОС выделяет свободный порт, представленный целым числом. Вместе с IP-адресом они составляют полный адрес в процесса в сети. Два процесса могут установить соединение между собой, если хотя бы один из них знает полный адрес другого (например, 123.45.67.89:1234 или mydomain.com:1234). Также для соединения необходимо знать имя протокола, по которому данный сокет работает (TCP, UDP).

Специально для передачи сообщений между процессами созданы два протокола: TCP и UDP. Изначально существовал только TCP, так как протокол еще на стадии проекта подразумевал надежную (без потерь и ошибок) доставку сообщений в том же порядке, в каком они были отправлены. Но так как какие-то пакеты могли затеряться по пути, а следующие не отдавались, пока не будет пересланы предыдущие, то такая пересылка могла занимать существенное время. Не для всех приложений надежность важна больше скорости.

Для многих игр реального времени, систем передачи потокового видео и голоса гораздо важнее получать самые последние данные, а незначительными потерями можно пренебречь. Поэтому в дополнение к TCP был также создан протокол UDP. UDP является протоколом без состояния, потому что он отдает сообщения сразу по мере их поступления. Благодаря этому сервер, использующий UDP, занимает меньше памяти, а потому может принимать больше запросов от большего количества пользователей, чем если бы он использовал TCP. Отсюда, простое правило: нужна скорость — использую UPD, надежность — TCP.

В OpenFL все сетевые классы располагаются в пакете ```openfl.net.*```. Для UDP-сокетов предназначен класс DatagramSocket, для TCP — Socket и XMLSocket. Первые два работают с бинарными данными, а последний сам кодирует и декодирует сообщения из бинарного представления, в котором они передаются по сети, в строки (UTF) и обратно, а также буферизирует все поступающие данные и разделяет сообщения по специальному нулевому символу (символ с кодом \0).

В целом все эти классы работают сходным образом:
1. Сначала вызывается метод ```socket.connect()```.
2. После возникновения события ```Event.CONNECT```, мы можем отсылать сообщения (методы ```socket.send()``` или ```socket.writeXxx()```).
3. Когда приходят новые данные с сервера, возникает событие ```DataEvent.DATA```, в объекте которого находятся сами данные: ```event.data``` (для Socket — событие ```ProgressEvent.SOCKET_DATA``` и данные нужно считывать из буфера методами ```socket.readXxx()```).
4. При разрыве соединения возникает событие ```Event.CLOSE``` или ```IOErrorEvent.IO_ERROR```, после чего мы можем попытаться переподключиться. Также при подключении может возникнуть событие ```SecurityErrorEvent.SECURITY_ERROR```. Это значит, что сервер не возвращает подходящий crossdomain.xml или используемый порт меньше 1024. При завершении работы сокеты всегда нужно закрывать явно (```socket.close()```), иначе на другом конце будут продолжать ждать сообщений целую вечность.

Вот такая несложная общая схема с четырьмя действиями: соединение, чтение, запись, закрытие. Реализуем для начала самый простой случай использования сокетов, когда XMLSocket вплетен непосредственно в модель (разбор серверной части будет в следующем разделе):

```haxe
class DresserModel
{
	// Settings
	// State
	private var socket:XMLSocket;
	public var state(default, set):Array<Int> = [];
	public function set_state(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(state, value))
		{
			state = value;
			// Dispatch
			stateChangeSignal.dispatch(value);
		}
		return value;
	}
	// Signals
	public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

	public function new()
	{
		socket = IoC.getInstance().getSingleton(XMLSocket);
		// Listeners
		socket.addEventListener(Event.CONNECT, socket_connectHandler);
		socket.addEventListener(DataEvent.DATA, socket_dataHandler);
	}
	public function load():Void
	{
		send({command: "get", name: "dresserState"});
	}
	public function changeItem(itemIndex:Int, frame:Int):Void
	{
		var data = {};
		Reflect.setField(data, Std.string(itemIndex), frame);
		send({
			command: "update",
			name: "dresserState",
			data: data
		});
	}
	private function send(data:Dynamic):Void
	{
		Log.debug('<< Send: $data');
		socket.send(Json.stringify(data));
	}
	private function processCommands(commands:Array<Dynamic>):Void
	{
		for (command in commands)
		{
			switch command.command:
			{
                case "get" | "set" | "save":
                    if (command.name == "dresserState")
                    {
                        state = command.data;
                    }
                case "update":
                    if (command.name == "dresserState")
                    {
                        for (ii in Reflect.fields(command.data))
                        {
                            var itemIndex = Std.parseInt(ii);
                            var frame = Reflect.field(command.data, ii);
                            state[itemIndex] = frame;
                            itemChangeSignal.dispatch(itemIndex, frame);
                        }
                    }
			}
		}
	}
	private function socket_connectHandler(event:Event):Void
	{
		load();
	}
	private function socket_dataHandler(event:DataEvent):Void
	{
		try
		{
			var data = Json.parse(event.data);
			var commands:Array<Dynamic> = Std.isOfType(data, Array) ? data : [data];
			processCommands(commands);
		}
		catch (e:Exception)
		{
			Log.error(e);
		}
	}
}
```

В сокетах нет понятия метода, как в HTTP (GET, POST, etc). Поэтому, чтобы различать назначение сообщения, добавим в данные новое поле — command. То же самое можно сделать и для нашего HTTP-сервера, унифицировав, таким образом, протокол приложения, чтобы он не зависел от того, строим мы приложение на HTTP или на простых сокетах.

Как видим, снаружи модель с сокетам ничем не отличается от модели на HTTP или простой офлайн модели. Все они имеют один интерфейс, а потому их можно свободно использовать друг вместо друга.

Объект сокетов мы берем как синглтон (```socket = IoC.getInstance().getSingleton(XMLSocket);```), поэтому несколько разных моделей может использовать одно соединение. Само соединение устанавливается (connect) в одном месте — в Main:

```haxe
class Main extends Sprite
{
	// Settings
	private var host = "localhost";
	private var port = 5555;
	private var reconnectIntervalMs = 3000;
	// State
	private var socket:XMLSocket;

	public function new()
	{
		super();
		//...
		socket = ioc.getSingleton(XMLSocket);
		socket.addEventListener(Event.CLOSE, reconnectLater);
		socket.addEventListener(IOErrorEvent.IO_ERROR, reconnectLater);
		socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, reconnectLater);
		// Connect
		Log.debug('Connecting to ${host}:${port}...');
		socket.connect(host, port);
	}
	private function reconnectLater(?event:Event):Void
	{
		Timer.delay(function () {
			Log.debug('Reconnecting to ${host}:${port}...');
			socket.connect(host, port);
		}, reconnectIntervalMs);
	}
}
```

В принципе, так тоже можно писать игры... если они маленькие и их не нужно особенно поддерживать или изменять. Но поскольку на практике ни одно из этих условий, как правило, не выполняется, то мы на этом варианте останавливаться не будем.

Если мы решим создать модель для другой игры, но работающую по тому же протоколу, то нам придется скопировать части кода из первой модели. Например, сериализацию и парсинг сообщений. Как обычно, нас не устраивает, когда хоть какой-то код в проекте дублируются. Так, если что-то изменится в парсинге, то придется вносить одни и те же изменения во все модели. Это можно исправить вынесением все работы с сокетами в базовый класс Protocol:

```haxe
class Protocol implements IProtocol
{
	// Settings
	public var reconnectIntervalMs = 3000;
    public var url:String;
	// State
	private var socket(default, set):XMLSocket;
	private function set_socket(value:XMLSocket):XMLSocket
	{
		if (socket != value)
		{
			if (socket != null)
			{
				// Listeners
				socket.removeEventListener(Event.CONNECT, socket_connectHandler);
				socket.removeEventListener(Event.CLOSE, socket_closeHandler);
				socket.removeEventListener(DataEvent.DATA, socket_dataHandler);
				socket.removeEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
				socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			}
			socket = value;
			if (socket != null)
			{
				// Listeners
				socket.addEventListener(Event.CONNECT, socket_connectHandler);
				socket.addEventListener(Event.CLOSE, socket_closeHandler);
				socket.addEventListener(DataEvent.DATA, socket_dataHandler);
				socket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
				socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			}
		}
		return socket;
	}
	private var reconnectTimer:Timer;
	// Signals
	public var connectingSignal(default, null) = new Signal<IProtocol>();
	public var connectedSignal(default, null) = new Signal<IProtocol>();
	public var disconnectedSignal(default, null) = new Signal<IProtocol>();
	public var closedSignal(default, null) = new Signal<IProtocol>();
	public var reconnectSignal(default, null) = new Signal<IProtocol>();
	public var errorSignal(default, null) = new Signal<Dynamic>();

	public function new()
	{
		socket = IoC.getInstance().getSingleton(XMLSocket);
	}
	public function dispose():Void
	{
		if (reconnectTimer != null)
		{
			reconnectTimer.stop();
			reconnectTimer = null;
		}
		socket = null;
	}
	public function connect(?host:String, ?port:Int):Void
	{
        var urlParts = url != null ? url.split(":") : [];
        host = host != null ? host : urlParts[0];
        port = port != null ? port : Std.parseInt(urlParts[1]);
		close();
		Log.debug('Connecting to ${host}:${port}...');
		socket.connect(host, port);
	}
	public function close():Void
	{
		if (reconnectTimer != null)
		{
			reconnectTimer.stop();
			reconnectTimer = null;
		}
		if (socket != null && socket.connected)
        {
            socket.close();
        }
	}
	private function reconnectLater():Void
	{
		reconnectTimer = Timer.delay(function () {
			connect();
			if (reconnectTimer != null)
			{
				reconnectTimer.stop();
				reconnectTimer = null;
			}
		}, reconnectIntervalMs);
	}
	private function send(data:Dynamic):Void
	{
		Log.debug('<< Send: $data');
		socket.send(Json.stringify(data));
	}
    // Override
	private function processCommands(commands:Array<Dynamic>):Void
	{
	}
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
		try
		{
			var data = Json.parse(event.data);
			var commands:Array<Dynamic> = Std.isOfType(data, Array) ? data : [data];
			processCommands(commands);
		}
		catch (e:Exception)
		{
			Log.error(e);
		}
	}
	private function socket_ioErrorHandler(event:IOErrorEvent):Void
	{
		Log.error('Socket IO ERROR $event');
		reconnectLater();
	}
	private function socket_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		Log.error('Socket SECURITY ERROR event: $event errorID: ${event.errorID}');
		reconnectLater();
	}
}
class DresserModel extends Protocol implements IDresserProtocol
{
	// State
	public var state(default, set):Array<Int> = [];
	public function set_state(value:Array<Int>):Array<Int>
	{
		if (value == null)
		{
			value = [];
		}
		if (!ArrayUtil.equal(state, value))
		{
			state = value;
			// Dispatch
			stateChangeSignal.dispatch(value);
		}
		return value;
	}
	// Signals
	public var stateChangeSignal(default, null) = new Signal<Array<Int>>();
	public var itemChangeSignal(default, null) = new Signal2<Int, Int>();

	public function load():Void
	{
		send({command: "get", name: "dresserState"});
	}
	public function changeItem(itemIndex:Int, frame:Int):Void
	{
		var data = {};
		Reflect.setField(data, Std.string(itemIndex), frame);
		send({
			command: "update",
			name: "dresserState",
			data: data
		});
	}
	override private function processCommands(commands:Array<Dynamic>):Void
	{
		super.processCommands(commands);
		for (command in commands)
		{
			if (command.command == "set")
			//...
		}
	}
	override private function socket_connectHandler(event:Event):Void
	{
		super.socket_connectHandler(event);
		load();
	}
}
```

Почему Protocol? Потому что DresserModel является фактически реализацией нашего протокола взаимодействия с сервером для dress-up-игр, какой-нибудь ColoringModel — это протокол для раскрасок и так далее. Вот и выходит, что все они протоколы.

Далее класс проходит те же этапы развития, что и для HTTP-версии, разобранной [ранее](01_client_21.md). Из Protocol обособляются классы для пересылки (transport) и кодирования (parser) сообщений. Это позволяет свободно сочетать разные способы пересылки и разные способы кодирования в одном алгоритме:

```haxe
class Protocol implements IProtocol
{
    //...
	private var transport(default, set):ITransport;
	private function set_transport(value:ITransport):ITransport
	{
		if (transport != value)
		{
			if (transport != null)
			{
				isConnecting = false;
				// Listeners
				transport.connectingSignal.remove(transport_connectingSignalHandler);
				transport.connectedSignal.remove(transport_connectedSignalHandler);
				transport.disconnectedSignal.remove(transport_disconnectedSignalHandler);
				transport.closedSignal.remove(transport_closedSignalHandler);
				transport.reconnectSignal.remove(transport_reconnectSignalHandler);
				transport.receiveDataSignal.remove(transport_receiveDataSignalHandler);
				transport.errorSignal.remove(transport_errorSignalHandler);
			}
			transport = value;
			if (transport != null)
			{
				// Listeners
				transport.connectingSignal.add(transport_connectingSignalHandler);
				transport.connectedSignal.add(transport_connectedSignalHandler);
				transport.disconnectedSignal.add(transport_disconnectedSignalHandler);
				transport.closedSignal.add(transport_closedSignalHandler);
				transport.reconnectSignal.add(transport_reconnectSignalHandler);
				transport.receiveDataSignal.add(transport_receiveDataSignalHandler);
				transport.errorSignal.add(transport_errorSignalHandler);
			}
		}
		return transport;
	}
	private var parser:IParser;
	private function get_parser():IParser
	{
		if (parser == null)
		{
			parser = IoC.getInstance().getSingleton(parserType);
		}
		return parser;
	}
	// Signals
	public var connectingSignal(default, null) = new Signal<IProtocol>();
	public var connectedSignal(default, null) = new Signal<IProtocol>();
	public var disconnectedSignal(default, null) = new Signal<IProtocol>();
	public var closedSignal(default, null) = new Signal<IProtocol>();
	public var reconnectSignal(default, null) = new Signal<IProtocol>();
	public var errorSignal(default, null) = new Signal<Dynamic>();

    public function new()
	{
		transport = IoC.getInstance().getSingleton(ITransport);
        transport.url = url;
        parser = IoC.getInstance().getSingleton(IParser);
	}
	public function dispose():Void
	{
		transport = null;
		parser = null;
	}
	public function connect(?host:String, ?port:Int):Void
	{
		transport.connect(host, port);
	}
	public function close():Void
	{
        transport.close();
	}
	private function send(data:Dynamic):Void
	{
		if (!transport.isConnected)
		{
			connect();
			return;
		}
		var plainData:Dynamic = parser.serialize(data);
		Log.debug('<< Send: $data -> $plainData');
		transport.send(plainData);
	}
	private function processCommands(commands:Array<Dynamic>):Void
	{
	}
    //...
	private function transport_receiveDataSignalHandler(plainData:Dynamic):Void
	{
		var data:Array<Dynamic>;
		try
		{
			data = parser.parse(plainData);
		}
		catch (e:Exception)
		{
			Log.error('Error while parsing data: $plainData! $e \n${e.details()}');
			return;
		}
		if (data != null)
		{
            try
            {
                processCommands(data);
            }
            catch (e:Exception)
            {
                Log.error('Error while processing commands: $data! $e \n${e.details()}');
            }
		}
	}
}
```

Как будет выглядеть парсер и транспорт, догадаться нетрудно:

```haxe
class JSONParser implements IParser
{
	public function serialize(data:Dynamic):String
	{
		return Json.stringify(data);
	}
	public function parse(plainData:String):Dynamic
	{
		return plainData == null ? null : Json.parse(plainData);
	}
}
class UTFSocketTransport implements ITransport
{
	// Settings
	public var reconnectIntervalMs = 3000; // Set 0 to disable
	public var url:String;
	// State
	private var socket(default, set):XMLSocket;
	private function set_socket(value:XMLSocket):XMLSocket
	{
		if (socket != value)
		{
			if (socket != null)
			{
				// Listeners
				socket.removeEventListener(Event.CONNECT, socket_connectHandler);
				socket.removeEventListener(Event.CLOSE, socket_closeHandler);
				socket.removeEventListener(DataEvent.DATA, socket_dataHandler);
				socket.removeEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
				socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			}
			socket = value;
			if (socket != null)
			{
				// Listeners
				socket.addEventListener(Event.CONNECT, socket_connectHandler);
				socket.addEventListener(Event.CLOSE, socket_closeHandler);
				socket.addEventListener(DataEvent.DATA, socket_dataHandler);
				socket.addEventListener(IOErrorEvent.IO_ERROR, socket_ioErrorHandler);
				socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socket_securityErrorHandler);
			}
		}
		return socket;
	}
	public var isConnecting(default, null):Bool = false;
	public var isConnected(get, null):Bool;
	public function get_isConnected():Bool
	{
		return socket != null && socket.connected;
	}
	private var reconnectTimer = new Timer(0, 1);
	// Signals
	public var connectingSignal(default, null) = new Signal<ITransport>();
	public var connectedSignal(default, null) = new Signal<ITransport>();
	public var disconnectedSignal(default, null) = new Signal<ITransport>();
	public var closedSignal(default, null) = new Signal<ITransport>();
	public var reconnectSignal(default, null) = new Signal<ITransport>();
	public var receiveDataSignal(default, null) = new Signal<Dynamic>();
	public var errorSignal(default, null) = new Signal<Dynamic>();

	public function new()
	{
		reconnectTimer.addEventListener(TimerEvent.TIMER, reconnectTimer_timerSignalHandler);
	}
	public function dispose():Void
	{
		reconnectTimer.stop();
		if (socket != null && socket.connected)
        {
            socket.close();
        }
		socket = null;
	}
	public function connect(?host:String, ?port:Int):Void
	{
		if (socket == null)
		{
			socket = IoC.getInstance().create(XMLSocket);
		}
        var urlParts = url != null ? url.split(":") : [];
        host = host != null ? host : urlParts[0];
        port = port != null ? port : Std.parseInt(urlParts[1]);
		close();// Close previous
		isConnecting = true;
		socket.connect(host, port);
		connectingSignal.dispatch(this);
	}
	public function close():Void
	{
		isConnecting = false;
		reconnectTimer.stop();
		if (socket != null && socket.connected)
		{
			socket.close();
		}
	}
	private function reconnectLater():Void
	{
		if (isConnected || isConnecting || reconnectIntervalMs < 0)
		{
			return;
		}
		if (reconnectIntervalMs == 0)
		{
			// Instant reconnect
			reconnectTimer_timerSignalHandler(null);
			return;
		}
		reconnectTimer.delay = reconnectIntervalMs;
		reconnectTimer.start();
	}
	public function send(plainData:Dynamic):Void
	{
		if (socket == null || !isConnected)
		{
			if (!isConnected)
			{
				connect();
			}
			Log.error('Cannot send $plainData because socket: $socket is not connected!');
			return;
		}
		socket.send(plainData);
	}
	private function socket_connectHandler(event:Event):Void
	{
		isConnecting = false;
		connectedSignal.dispatch(this);
	}
	private function socket_closeHandler(event:Event):Void
	{
		disconnectedSignal.dispatch(this);
		closedSignal.dispatch(this);
		reconnectLater();
	}
	private function socket_dataHandler(event:DataEvent):Void
	{
		Log.debug('>> Data received: ${event.data}');
		receiveDataSignal.dispatch(event.data);
	}
	private function socket_ioErrorHandler(event:IOErrorEvent):Void
	{
		isConnecting = false;
		Log.error('Socket IO ERROR $event');
		errorSignal.dispatch(event);
		reconnectLater();
	}
	private function socket_securityErrorHandler(event:SecurityErrorEvent):Void
	{
		isConnecting = false;
		Log.error('Socket SECURITY ERROR event: $event errorID: ${event.errorID}');
		errorSignal.dispatch(event);
		reconnectLater();
	}
	private function reconnectTimer_timerSignalHandler(event:TimerEvent):Void
	{
		reconnectTimer.stop();
		// Dispatch
		reconnectSignal.dispatch(this); // (URL can be changed here)
		if (!isConnecting && !isConnected)
		{
			connect();
		}
	}
}
```

Функция переподключения (```reconnectLater()```) переходит в transport, так как транспорт может быть только один на приложение, а протоколов, его использующих, сколько угодно. Нам нужно переподключаться только один раз, поэтому эта функция не может находится в протоколе.

Теперь потомки Protocol отвечают за клиентский протокол, Parser — за серверные протоколы, а Transport — за протоколы уровня сети и передачи потоков байтов. Если серверный протокол отличается от клиентского, то все эти отличия устраняются в специальной реализации парсера. Так что Protocol получает данные всегда в одном и том же виде, который и называется условно клиентским протоколом. Если взаимодействие клиентской и серверной команды налажено и работают в унисон, то их форматы сообщений должны совпадать.

Теперь мы можем отдельно подбирать протокол сервера (Parser) и сетевой протокол (Transport) для кодирования и передачи наших сообщений. В DresserProtocol и других наследниках Protocol будет использоваться только клиентский формат сообщений. Так мы попутно разделили еще и клиентскую и серверную разработку. Если их форматы не совпадают, это устраняется всего лишь в одном месте — в парсере. Также можно вместо обычного парсера использовать MultiParser, рассмотренный [ранее](01_client_21.md), который может переключать версии серверного протокола на лету.

Вот так на примере самого простого приложения мы создали шаблон приложения, которое поддерживает офлайн и онлайн режимы работы, умеет подстраиваться под разные сетевые протоколы (HTTP, TCP- и UDP-сокеты) и серверные форматы данных. Шаблон, в котором удобно расширять, модифицировать и настраивать функционал, и при всем при этом весь написанный код можно использовать повторно в других проектах — полностью или частично. Это значит, что каждое исправление бага в одном проекте повышает надежность кода и во всех существующих и будущих проектах, качество постоянно растёт — так сказать, накапливается, а баги испаряются и больше не повторяются.

Данный шаблон фактически является фреймворком — каркасом для любых новых проектов, создающим прочную, но в то же время гибкую и податливую к изменениям, структуру приложения. Это делает разработку быстрой, а последующую поддержку кода — комфортной.

Закончив с клиентом, проведем аналогичную работу с [сервером](02_server_01.md).

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/g_sockets/client_haxe/src/)

[< Назад](01_client_21.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](02_server_01.md)
