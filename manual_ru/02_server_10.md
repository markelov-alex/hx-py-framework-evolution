# Эволюция игрового фреймворка. Сервер 10. Разделение на слои

## Отделение логики от инфраструктуры

[Сейчас](02_server_09.md) наше приложение цельное и неразделимое, а потому максимально "нереюзабельное". Другими словами, мы не можем повторно использовать отдельные его части, так как все они жестко связаны друг с другом. Хоть логика и вынесена в отдельную функцию `handle_command()`, но в `handle_connection()` по-прежнему вызывает именно эту функцию без возможности подставить вместо нее другую. Если мы захотим написать новое приложение с другой логикой, то нам придется копировать и `handle_connection()`. Конечно, нас это не устраивает.

В качестве решения можно передавать ссылку на handle_command в параметрах handle_connection(). Также можно вынести обе функции в класс, а в подклассах их переопределять. А можно логику (обработку объектов) и инфраструктуру (обмен объектами) вообще реализовать в двух разных классах.

В классе можно хранить собственный контекст из переменных-членов (свойств),  группировать методы, переопределять их в подклассах и так далее. Это задает два магистральных пути развития в серверной разработке. С одной стороны мы можем подготовить разные типы и версии функционала по передаче объектов (Server), с другой — наделать кучу разных игр (Logic). Все это независимо друг от друга. Единственное условие, которое должно сублюдаться, это чтобы класс логики содержал метод с такой сигнатурой: `handle_command(self, i, command)`.

```python
class SocketServer:
    # Settings
    host = ""
    port = 5555

    def __init__(self, logic, host=None, port=None):
        url_parts = host.split(":") if host else None
        if url_parts:
            self.host = url_parts[0]
            self.port = port if port else (
                int(url_parts[1]) if len(url_parts) > 1 else self.port)
        self.logic = logic
        self.writers = []

    def run(self):
        asyncio.run(self.main())

    async def main(self):
        print(f"Start server: {self.host}:{self.port}")
		server = await asyncio.start_server(handle_connection, host, port)
		async with server:
			await server.serve_forever()

    async def handle_connection(self, reader, writer):
        # ...

class MyLogic:
	# global storage -> self.storage
	def __init__(self):
		self.storage = {}

    def handle_command(self, i, command):
    	# ...
```

Код запуска при этом немного изменится:

```python
HOST, PORT = "", 5554
if __name__ == "__main__":
    server = SocketServer(MyLogic(), HOST, PORT)
    server.run()
```

Таким образом, инфраструктура, отвечающая за способ обмена данными, отделена от логики приложения, что позволяет разрабатывать и развивать их отдельно. Но это только первый шаг в этом направлении. Следующий шаг — отделить способ транспортировки сообщений (сокеты) от формата их кодирования (JSON).

## Разделение форматирования и передачи сообщений

Отделить логику приложения от инфраструктуры было хорошей идеей. В результате логика просто получает объекты команд и не задумывается, откуда и как они берутся. А потом отдает серверу другие объекты команд и не думает, куда они деваются. Другими словами, классы логики лишь преобразуют одни команды в другие, попутно меняя свое состояние. За все остальное отвечает класс сервера (SocketServer).

Теперь заглянем в оставшийся после разделения класс инфраструктуры — в сам SocketServer. Заглянем и увидим, что в нем определенный способ обработки сообщений (JSON) жестко завязан на определенный способ их передачи (TCP-сокеты). И если мы захотим использовать другой формат передачи данных, то нам заодно придется переписать, а точнее продублировать, кучу кода, к формату не относящегося.

Первое решение, что приходит на ум, выделить этот код в отдельный метод — будем из handle_connection() вызывать handle_bytes():

```python
class SocketServer:
	# ...
	async def handle_connection(self, reader, writer):
		print("+Connected")
		self.writers.append(writer)
		unparsed_bytes = b""
		while True:
			# Receive
			request_bytes = await reader.read(1024)
			if not request_bytes:
				break
			request_bytes = unparsed_bytes + request_bytes
			# Process
			to_self_bytes, to_all_bytes, unparsed_bytes = self.handle_bytes(request_bytes)
			# Send
			if to_self_bytes:
				writer.write(to_self_bytes)
                await writer.drain()
			if to_all_bytes:
				for w in self.writers:
					w.write(to_all_bytes)
					await w.drain()
        self.writers.remove(writer)
		writer.close()
		print(f"-Disconnected")

	def handle_bytes(self, i, request_bytes):
		# Decode request
		request = request_bytes.decode("utf8")
		# Make response
		try:
			# Parse request
			command = json.loads(request)
			# Process request
			to_self_command, to_rest_command = self.logic.handle_command(i, command)
		except Exception as e:
			print(f"[SERVER#{i}] Error while parsing or processing: {request} {traceback.format_exc()}")
			to_self_command, to_rest_command = {"error": str(e)}, None
		# Serialize response
		self_response = json.dumps(to_self_command) if to_self_command else None
		all_response = json.dumps(to_rest_command) if to_rest_command else None
		# Encode response
		to_self_bytes = self_response.encode("utf8") + b"\x00" if self_response else None
		to_all_bytes = all_response.encode("utf8") + b"\x00" if all_response else None
		return to_self_bytes, to_all_bytes
```

Теперь, например, если мы захотим изменить JSON на XML, то нам нужно наследоваться от SocketServer и переопределить handle_bytes(). Но при таком подходе остается пару неприятностей. Во-первых, нам нужно знать структуру метода и не забыть вызвать handle_command(), когда нужно. Во-вторых, сериализация данных проводится два раза: для to_self_command и to_rest_command. Налицо дублирование кода.

Пусть первые две проблемы можно решить рефакторингом к паттерну шаблонный метод (Refactoring to the template method design pattern):

```python
	def handle_bytes(self, i, request_bytes):
		# Parse
		command = self.parse(request_bytes)
		# Process
		to_self_command, to_rest_command = self.logic.handle_command(i, command)
		# Serialize
		to_self_bytes = self.serialize(to_self_command)
		to_all_bytes = self.serialize(to_rest_command)
		return to_self_bytes, to_all_bytes
```

Но остается третий и, пожалуй, главный недостаток. Код по доставке (сокеты) и код по форматированию (JSON) остается в одном классе. Это значит, что если нужно создать классы для двух типов сокетов (TCP и UDP) и трех видов форматов (JSON, YML, XML), то в итоге мы получим 2 * 3 = 6 классов для всех возможных комбинаций. Хотя должно быть по идее 2 + 3 = 5. Пусть 6 и 5 отличаются не сильно, но иметь в качестве закона возрастания кода умножение вместо сложения дает уже на следующем этапе избыточность в 33 % (3 * 3 = 9, 3 + 3 = 6). И то, что код при этом не дублируется заслуга Python'а (множественное наследование), а не наша.

Поэтому лучше поступить по-нормальному и разнести доставку и первичную обработку сообщений по разным классам:

```python
class Parser:
    def parse(self, data_bytes):
        return data_bytes, b""

    def serialize(self, data):
        return data


class JSONParser(Parser):
    def parse(self, data_bytes):
        # Get unparsed_bytes
        data_bytes, unparsed_bytes = data_bytes.rsplit(b"\x00", 1)
        # bytes -> list of str
        data_str = data_bytes.decode("utf8")
        message_list = data_str.split("\x00")
        # Parse JSON commands (suppose, a command cannot be a list)
        result = []
        for message in message_list:
            if not message:
                continue
            commands = json.loads(message)
            if not commands:
                continue
            if isinstance(commands, list):
                result.extend(commands)
            else:
                result.append(commands)
        return result, unparsed_bytes

    def serialize(self, data):
        if not data:
            return b""
        data_str = json.dumps(data)
        data_bytes = data_str.encode("utf8") + b"\x00"
        return data_bytes

class MyLogic:
	parser = JSONParser()  # Use JSON by default

    def __init__(self, parser) -> None:
        super().__init__()
        if parser:
        	self.parser = parser

    def handle_bytes(self, i, request_bytes):
        unparsed_bytes = b""
        try:
            # Parse
            commands, unparsed_bytes = self.parser.parse(request_bytes)
            # Process
            to_self_commands, to_all_commands = self.handle_commands(i, commands)
        except Exception as e:
            to_self_commands, to_all_commands = {"error": str(e)}, None
        # Serialize
        to_self_bytes = self.parser.serialize(to_self_commands)
        to_all_bytes = self.parser.serialize(to_all_commands)
        return to_self_bytes, to_all_bytes, unparsed_bytes

    def handle_commands(self, i, commands):
    	# Custom logic
		key = command.get("key")
		code = command.get("code")
		...

class SocketServer:
	# ...
	async def handle_connection(self, reader, writer):
		# ...
		while True:
			# ...
			to_self_bytes, to_all_bytes, unparsed_bytes = self.logic.handle_bytes(request_bytes)
			# ...
		# ...
```

Сервер может за раз принять одно сообщение, а может принять и несколько — в зависимости от того, сколько в потоке байтов присутствует разделителей. Сколько было в буфере, столько и возвращает. Да и в каждом сообщении, в принципе, можно отправлять сразу несколько команд вместо одной. Поэтому логично в парсере возвращать сразу список команд, и условиться, что всегда возвращаться будет только список. Соответственно, и handle_command() будет принимать и возвращать команды только списками. Потому он и переименован теперь в handle_commands().

То, что мы передаем в парсер байты, а не декодированные в UTF-8 строки, позволяет нам реализовывать в парсерах собственные кастомные бинарные протоколы. Разграничение сообщений производится в парсере по этой же причине. Если удалось распарсить команду, она возвращается. Если нет — возвращаются байты, чтобы позже к ним добавить новые и повторить попытку.

Добавим парсер в приложение как составную часть логики, а не сервера, оставив за последним простую передачу и прием абстрактных байтов, а за логикой всякую их обработку:

```python
HOST, PORT = "", 5554
if __name__ == "__main__":
	logic = MyLogic(JSONParser())
    server = SocketServer(logic, HOST, PORT)
    server.run()
```

В результате передача байтов и форматирование из них сообщений отделены друг от друга в две отдельные сущности. Теперь эти два направления могут развиваться совершенно свободно. Но для этого мы вынуждены были добавить в класс логики метод handle_bytes(), который придется дублировать в каждом новом приложении. Непорядок. Надо устранить.

## Разделение логики на класс приложения и контроллеры

На данный момент мы уже выделили функционалы по передаче данных (SocketServer) и форматированию данных в команды и обратно (Parser). Теперь это отдельные классы, которые выполняют только свою особую задачу и ничего больше. Максимум, вызывают метод класса следующего уровня (SocketServer вызывает logic.handle_bytes()), чтобы передать данные дальше по цепочке.

Чистота классов, отсутствие в них посторонних функциональностей — не наши причуды и хотелки. Они позволяют нам избегать дублирования кода. Ведь если мы берем какой-нибудь класс с двойной функциональностью (тот, который решает две задачи) ради одной из них, мы автоматически получаем в нагрузку и вторую. А что если нам ее не надо? Или надо, но другую. Придется переопределять эту вторую функциональность, а значит, создавать новый класс, плодить новую сущность.

Именно в такой ситуации находится у нас сейчас класс логики. Он одновременно реализует и общий для всякой логики шаблон обработки данных handle_bytes(), и полностью частную (кастомную) реализацию handle_commands(). Если мы станем реализовывать другую логику, нам придется дублировать в ней содержимое handle_bytes(). Или мы наследуемся от общего класса и переопределим handle_commands(). Тогда можно вынести общий функционал в отдельный класс Logic, а кастомную логику реализовывать, переопределяя только один метод — handle_commands():

```python
class Logic:
	parser = JSONParser()  # Use JSON by default

    def __init__(self, parser) -> None:
        super().__init__()
        if parser:
        	self.parser = parser

    def handle_bytes(self, i, request_bytes):
        unparsed_bytes = b""
        try:
            # Parse
            commands, unparsed_bytes = self.parser.parse(request_bytes)
            # Process
            to_self_commands, to_all_commands = self.handle_commands(i, commands)
        except Exception as e:
            to_self_commands, to_all_commands = {"error": str(e)}, None
        # Serialize
        to_self_bytes = self.parser.serialize(to_self_commands)
        to_all_bytes = self.parser.serialize(to_all_commands)
        return to_self_bytes, to_all_bytes, unparsed_bytes

    def handle_commands(self, i, commands):
		pass  # Implement in subclasses

class MyLogic(Logic):
    def handle_commands(self, i, commands):
    	# Custom logic
    	to_self_commands, to_all_commands = [], []
    	for command in commands:
			key = command.get("key")
			code = command.get("code")
			...
		return to_self_commands, to_all_commands
```

Допустим, нам нужно сделать серверы по игре шахматы, шашки, крестики-нолики... Для каждого создается отдельный класс логики, где переопределяется лишь один метод handle_commands() — и никакого дублирования кода. Передаем в конструктор SocketServer первым аргументом объект логики, и сервер готов к использованию:

```python
class ChessLogic(Logic):
    def handle_commands(self, i, commands):
    	...

class CheckersLogic(Logic):
    def handle_commands(self, i, commands):
    	...

HOST, PORT = "", 5554
if __name__ == "__main__":
	logic = CheckersLogic(JSONParser())
    server = SocketServer(logic, HOST, PORT)
    server.run()
```

Но, возможно, у вас уже возник закономерный вопрос. А что, если мы захотим создать сервер, где можно было бы по выбору играть и в шахматы, и в шашки? Вот тут уже придется изгаляться. Здесь нужен какой-то класс-диспетчер логики, который будет перенаправлять команды к соответствующему обработчику:

```python
class ComboLogic(Logic):
    def __init__(self, parser) -> None:
        super().__init__(parser)
		self.chess = ChessLogic(parser)
		self.checkers = CheckersLogic(parser)
		# self.chess.storage = self.checkers.storage = self.storage

    def handle_commands(self, i, commands):
    	# Custom logic
    	to_self_commands, to_all_commands = [], []
    	for command in commands:
			key = command.get("key")
			if key == "chess":
				s, a = self.chess.handle_commands(i, commands)
				to_self_commands.extend(s)
				to_all_commands.extend(a)
			elif key == "checkers":
				s, a = self.checkers.handle_commands(i, commands)
				to_self_commands.extend(s)
				to_all_commands.extend(a)
		return to_self_commands, to_all_commands

HOST, PORT = "", 5554
if __name__ == "__main__":
	logic = ComboLogic(JSONParser())
    server = SocketServer(logic, HOST, PORT)
    server.run()
```

Несложно заметить в цикле обработки команд явное дублирование кода (`handle_commands()` и `extend()`). Попробуем его устранить с помощью словаря:

```python
class ComboLogic(Logic):
    def __init__(self, parser) -> None:
        super().__init__(parser)
		self.logic_by_key = {
			"chess": ChessLogic(parser),
			"checkers": CheckersLogic(parser),
		}
		# for logic in self.logic_by_key.items():
		# 	logic.storage = self.storage

    def handle_commands(self, i, commands):
    	# Custom logic
    	to_self_commands, to_all_commands = [], []
    	for command in commands:
			key = command.get("key")
			logic = self.logic_by_key.get(key)
			if logic:
				s, a = logic.handle_commands(i, [command])
				to_self_commands.extend(s)
				to_all_commands.extend(a)
		return to_self_commands, to_all_commands
```

Что ж получилось неплохо. Но теперь мы получили еще одну общую функциональность в области логики приложения. Теперь у нас их две: Logic — базовый класс для одиночной логики, и ComboLogic — диспетчер логики между одиночными логиками. Очевидно, что первый класс — это частный случай второго. Так зачем нам плодить сущности? Объединим их в один класс Logic, так что у нас по умолчанию будет доступна поддержка нескольких логик. А словарь с логиками вынесем в настройки. Тогда получим примерно такую настройку сервера:

```python
HOST, PORT = "", 5554
if __name__ == "__main__":
	logic_by_key = {
		"chess": ChessLogic(),
		"checkers": CheckersLogic(),
	}
	logic = Logic(JSONParser(), logic_by_key)
    server = SocketServer(logic, HOST, PORT)
    server.run()
```

Сейчас класс логики выбирается по одному из свойств команды — key. Но в последствии, когда будут реализованы комнаты и перемещения игроков по ним, можно будет выбирать обработчик команды по тому, в какой комнате, в какой игре находится пользователь. Если он в покер-руме, берется логика покера, если за шахматным столом — логика шахмат.

Возможно, вы заметили, что парсер в конструктор ChessLogic и CheckersLogic больше не передается. Ведь он не используется, поскольку в этих классах вызывается только handle_commands(), а handle_bytes() вызывается только у Logic. Налицо фактическое разделение логики на два типа классов: диспетчер и собственно реализации логики. Последним нужен только интерфейс с сигнатурой метода handle_commands(). А диспетчер всегда один и тот же для всех приложений и никогда не переопределяется. Фактически он превратился в движок приложения, который занимается парсингом потока байтов, получаемых с сервера, поиск подходящего класса для исполнения получившихся команд и сериализации результата.

Поэтому класс Logic уместнее будет переименовать в Engine, или, лучше, в Application, а отдельные логики — в контроллеры:

```python
class SocketApplication:
	parser = JSONParser()

    def __init__(self, parser, default_controller, controller_by_key=None) -> None:
        super().__init__()
        if parser:
        	self.parser = parser
        self.default_controller = default_controller
        self.controller_by_key = controller_by_key or {}
        self.storage = {}  # App state

	# ...

    def handle_commands(self, i, commands):
        result_self, result_all = [], []
        # Handle
        for command in commands:
            key = command.get("key")
            controller = self.controller_by_key.get(key, self.default_controller)
            if controller:
                controller.handle_command(self.storage, i, command, result_self, result_all)
        return result_self, result_all

class MyController:
    def handle_command(self, storage, i, command, result_self, result_all):
    	...

class ChessController:
    def handle_command(self, storage, i, command, result_self, result_all):
    	...

class CheckersController:
    def handle_command(self, storage, i, command, result_self, result_all):
    	...

HOST, PORT = "", 5554
if __name__ == "__main__":
	controller_by_key = {
		"chess": ChessLogic(),
		"checkers": CheckersLogic(),
	}
    app = SocketApplication(JSONParser(), MyController(), controller_by_key)
    server = SocketServer(app, HOST, PORT)
    server.run()
```

Отметим, что в контроллерах теперь не handle_commands(), а handle_command(). То есть команды обрабатываются по одной. Это удобнее, так как не нужно каждый раз делать обработку в цикле. И главное — диспетчер все равно будет передавать по одной команде, так как любая команда в массиве может отличатся и требовать своего собственного обработчика.

Также результат больше не возвращается через return, а передается в виде списков в аргументах. Это тоже упрощает реализацию.

И последнее. Так как контроллеры — это в сущности всего лишь часть общей логики приложения, то все они должны использовать одно состояние (storage). Сами контроллеры состояния не имеют и иметь не могут. Они — логика в самом чистом виде. Поэтому при каждом вызове handle_command() среди прочих аргументов передается и ссылка на состояние приложения.

В итоге, логика приложения разделилась на движок и контроллеры. Первый стандартным образом образом получает, обрабатывает и пересылает данные, а последние — реализуют кастомную логику в чистом виде, взаимодействуя с движком посредством готовых объектов-команд. Таким образом, логика у нас полностью отделена и от способа передачи сообщений по сети, и от формата этих сообщений. Логика отделена даже от другой логики (в разных контроллерах). Это всего лишь набор классов, не знающих друг о друге, и только движок (Application) знает, кого из них использовать для данной конкретной команды.

Последовательность обработки данных получается такая: Server -> Application -> Parser -> Controller. Разбиение всего приложения на 4 независимых друг от друга слоя позволяет классы каждого из них разрабатывать отдельно от классов других слоев. Все, что от них требуется — это держаться в рамках заданных им интерфейсов. Если интерфейсы остаются неприкосновенными, то любые изменения в одном слое никак не отразятся на всех других. В этом и заключается вся прелесть слоистой архитектуры.

## Состояние

Скажем напоследок пару слов о состоянии. В ООП подходе все само собой складывается так, что для каждой логической сущности создается программный объект с свойствами и методами. В свойствах хранится текущее состояние, в методах реализуются функции, которые его преобразуют. В результате все состояние приложения размазано тонким слоем по десяткам и сотням таких объектов. Чтобы сохранить состояние в файл, придется обойти все объекты, собрать все их свойства и перевести в простые JSON-объекты. А чтобы загрузить, восстановить приложение из файла, придется воссоздавать по иерархии JSON-объектов иерархию наших программных объектов, определять нужный класс для каждого, принимать во внимание параметры конструкторов, восстанавливать значения его свойств (даже приватных). В общем, ясно, что это очень и очень сложно и муторно.

Тут сначала может появится идея, что все свойства объекта можно просто хранить в словаре. И не перебирать свойства объекта, когда его нужно сохранить, а просто отдавать этот словарь. Следующей мыслью возникает вопрос. А зачем нам вообще восстанавливать все эти объекты — их иерархию и состояние? Почему не оперировать изначально чистой JSON-структурой? Тогда и объекты никакие нужны не будут, а будут одни функции. Простой набор функций.

По счастью, Python мультипарадигменный язык программирования, и на нем можно писать и в ООП-стиле, и в процедурном, и в функциональном. Мы начали с самой простой возможной реализации сервера, а потому делали его через простые функции (процедурный стиль). Поэтому состояние у нас было изначально в отдельном словаре — общем на все приложение.

Когда мы перешли к ООП, мы сохранили использование централизованного состояния. Мы не стали его рапределять по классам, потому что в этом не было никакого смысла. Классы мы применяли лишь для группировки функций и возможности подменять реализации некоторых из них в подклассах (см. паттерн [шаблонный метод](https://ru.wikipedia.org/wiki/%D0%A8%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD%D0%BD%D1%8B%D0%B9_%D0%BC%D0%B5%D1%82%D0%BE%D0%B4_(%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD_%D0%BF%D1%80%D0%BE%D0%B5%D0%BA%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F)). (Если же мы сможем так организовать методы, чтобы вообще не менять в них состояние, то перейдем к математической концепции функций — к функциональному стилю.)

Повезло нам с состоянием? Не совсем. Все дело в методике разработки. Всегда нужно начинать с самого простой возможной версии, а потом добавлять в нее только то, без чего нельзя обойтись. Тогда про многие проблемы вы даже и не узнаете, что они бывают.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/server_socket/v3/)

[< Назад](02_server_09.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](02_server_11.md)
