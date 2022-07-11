# Эволюция игрового фреймворка. Сервер 8. Асинхронное программирование

![](pics/02_server_08_01.png)

[Выше](02_server_08.md) мы рассмотрели, как появились генераторы, как они работают и как их можно использовать в роли сопрограмм. Еще [раньше](02_server_06.md) было разобрано, как реализовать асинхронность на колбеках с помощью модуля selectors. Теперь соединим оба материала и реализуем настоящую асинхронность — на сопрограммах (coroutines).

Вспомним вкратце, как сопрограммы произошли из генераторов. Всякая функция, содержащая инструкцию yield, становится генератором. Вызов такой "функции" не запустит ее выполнение, а вернет объект генераторного итератора (generator iterator). (Функция с yield — это просто такая форма записи итератора.) В этом объекте будет хранится позиция последней выполненной инструкции, так что при повторном вызове генератора выполнение продолжается с того места, на котором оно остановилось в прошлый раз. Генератор запускается так же, как и всякий другой итератор — функцией next() (или в цикле for-in, который вызывает next() неявно). А прерывается выполнение генератора инструкцией yield, которое при этом, подобно return, может возвращать значение. (Чтобы окончательно завершить выполнение генератора, нужно из него вызвать return.)

Вот так попеременными вызовами yield и next() управление программой может переходить между разными генераторами, что делает их неотличимыми от сопрограмм. Фактически это они и есть. Но сопрограммы не могут сами осуществлять такой переход. Нужна отдельная функция, которая, работая в бесконечном цикле, будет в нужный момент их переключать. Сопрограмма будет включаться вызовом next(), а прерываться — с yield. C выполнением yield, управление вновь вернется в основной цикл, который запустит другую сопрограмму. И так до бесконечности.

Теперь припомним главную проблему использования [колбеков](02_server_06.md). Они вызывались только для тех сокетов, про которые мы достоверно знали, что он готов. Соответственно, второй раз использовать сокет из того же колбека мы не могли, так как его готовность не гарантировалась. Аналогично, мы не можем использовать на чтение в той же функции и другие сокеты, потому что, если данные для них еще не пришли, то они заблокируют выполнение всей программы. Вообще всей.

Но генераторы, позволяющие прерывать в любом месте свое выполнение, решают эту проблему. Теперь перед каждым вызовом блокирующей функции мы можем вызвать yield и выйти из генератора, запомнив перед этим с каким сокетом связан данный генератор. Когда сокет окажется готов (или если он уже готов), выполнение генератора продолжится.

## Соединение селектора и генераторов. Первая версия асинхронности

Итак, переделаем [последнюю версию](02_server_06.md) сокет-сервера под использование генераторов: добавим в колбеки yield, а в основном цикле вызов колбека (`callback(sel, key.fileobj, mask)`) заменим на итерирование генератора (`next(_current_gen)`).

Сначала превратим колбеки из функций в генераторы, добавив в них yield:

```python
_selector = selectors.DefaultSelector()

def wait_for(fileobj):
    _selector.register(fileobj, selectors.EVENT_READ, _current_gen)

def main(host, port):
    # ...
	wait_for(serv_sock)
	yield  # same as: yield wait_for(serv_sock)
	sock, addr = serv_sock.accept()
    # ...

def handle_connection(sock, addr):
    # ...
	yield wait_for(sock)
	data = sock.recv(1024)
    # ...
```

Перед тем, как вызвать блокирующую функцию sock.accept() или sock.recv(), мы с помощью функции `wait_for()` регистрируем данный сокет в селекторе (на ожидание готовности чтения — selectors.EVENT_READ), указывая в параметре data ссылку на текущий генератор-сопрограмму. После чего сопрограмма вызывает yield и возвращается в основной цикл, откуда перед этим и была вызвана (`loop()`):

```python
def loop(main_gen):
	# ...
	while True:
		# ...
		events = _selector.select()
		for key, mask in events:
			# Unregister socket registered in wait_for()
			_selector.unregister(key.fileobj)
			# Continue coroutine
			_current_gen = key.data
			try:
				next(_current_gen)
			except StopIteration:
				# Generator returns, not yields (on disconnect)
				pass
```

Основной цикл вызывает selector.select(), тот возвращает список готовых сокетов, по которому выбирается и запускается соответствующая сопрограмма. Селектор возвращает список объектов SelectorKey, в поле fileobj которого хранится ссылка на сокет. А в поле data мы предусмотрительно поместили ссылку на сопрограмму, которая была приостановлена в ожидании данного сокета. После ее очередного запуска выполнение продолжится с момента вызова yield, то есть в нашем случае следующая инструкция будет или serv_sock.accept(), или sock.recv(). Селектор гарантирует, что они не блокируют выполнение, а исполнятся мгновенно.

Полный текст программы занимает всего 100 строк:

```python
import selectors
import socket
from inspect import isgenerator

# Loop

_ready = []
_current_gen = None
_selector = selectors.DefaultSelector()

def loop(main_gen):
    # global _ready, _selector
    assert isgenerator(main_gen)
    create_task(main_gen)
    while True:
        # Ready tasks
        while _ready:
            print(f"(Run task {_ready[0]}...)")
            _run(_ready.pop(0))

        # Ready IO
        print("Waiting for connections or data...")
        events = _selector.select()
        for key, mask in events:
            _selector.unregister(key.fileobj)
            gen = key.data
            _run(gen)

def create_task(gen):
    # global _ready
    assert isgenerator(gen)
    print(f"(Create task {gen}...)")
    _ready.append(gen)

def _run(gen):
    global _current_gen
    _current_gen = gen
    try:
        next(gen)
    except StopIteration:
        # Generator returns, not yields (on disconnect)
        pass

def wait_for(fileobj):
    # global _current_gen, _selector
    _selector.register(fileobj, selectors.EVENT_READ, _current_gen)

# Server

def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((host, port))
        serv_sock.listen(1)
        # serv_sock.setblocking(False)
        print("Server started")

        while True:
            wait_for(serv_sock)
            yield
            sock, addr = serv_sock.accept()  # Should be ready after wait_for()
            print("Connected by", addr)
            create_task(handle_connection(sock, addr))

def handle_connection(sock, addr):
    while True:
        # Receive
        try:
            yield wait_for(sock)
            data = sock.recv(1024)  # Should be ready after wait_for()
        except ConnectionError:
            print(f"Client suddenly closed while receiving")
            break
        print(f"Received {data} from: {addr}")
        if not data:
            break
        # Process
        if data == b"close":
            break
        data = data.upper()
        # Send
        print(f"Send: {data} to: {addr}")
        try:
            sock.send(data)  # Hope it won't block
        except ConnectionError:
            print(f"Client suddenly closed, cannot send")
            break
    sock.close()
    print("Disconnected by", addr)

HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    loop(main(HOST, PORT))
```

Вот мы и реализовали простейшую асинхронность на сопрограммах. Она лучше асинхронности на колбеках тем, что:
 - в сопрограммах можно выполнять несколько блокирующих функций при чем для разных сокетов, так как yield можно вызывать несколько раз и из разных мест; в колбеке может быть только один блокирующий вызов перед вызовом инструкции return;
 - для каждого блокирующего вызова нужен свой колбек, что в реальных программах приводит к неразберихе из-за большой вложенности колбеков друг в друга, известной как callback hell; такой код тяжело понять и сложно поддерживать; напротив, асинхронный код выглядит так же, как и синхронный, за исключением добавления yield (позже он заменятся на более подходящий тут await);
 - возможность использования исключений в сопрограммах так же, как в синхронных программах; колбеки вызываются из основного цикла движка, а значит, и исключения из колбеков будут подниматься прямо в движок, где мы их обработать не можем.

Уже этих трех достоинств сопрограмм достаточно, чтобы совершенно забыть о колбеках. В особенности, когда мы усовершенствуем механизмы асинхронного программирования до высшего уровня — модуля asyncio, и будем использовать более уместный await вместо yield.

Но прежде нам предстоит пройти еще несколько промежуточных этапов, чтобы полностью проследить всю эволюцию асинхронного программирования, как она исторически происходила в Python. Тем более, что большую часть пути мы уже прошли.

## Мимикрируем под исходники asyncio

Во-первых, проведем небольшой рефакторинг, чтобы привести уже разобранный нами код в тот вид, который был бы максимально похож на asyncio. Все имена переменных, функций и классов сделаем такими же, как там. Имея перед глазами минимальную рабочую версию asyncio и возможность экспериментировать с ней, нам будет легче разобраться в более сложной библиотечной ее версии. (Как и раньше, для простоты мы не проверяем готовность сокетов на запись (selectors.EVENT_WRITE). Без больших нагрузок все равно сокеты всегда будут доступны на запись.)

```python
def run(main):
    loop = get_event_loop()
    loop.run_forever(main)

loop = None

def get_event_loop():
    global loop
    if not loop:
        loop = SelectorLoop()
    return loop

class SelectorLoop:
    def __init__(self) -> None:
        super().__init__()
        self._selector = selectors.DefaultSelector()
        self._current_gen = None  # Currently executing generator
        self._ready = []
        self._run_forever_gen = None

    def run_forever(self, main_gen):
        self.create_task(main_gen)
        while True:  # Main loop
            self._run_once()

    def create_task(self, gen):
        self._ready.append(gen)

    def wait_for(self, fileobj):
        self._selector.register(fileobj, selectors.EVENT_READ, self._current_gen)
        yield  # Yield back to main loop to select other ready I/O objects

    def _run_once(self):
        self._process_tasks(self._ready)
        print("Waiting for connections or data...")
        events = self._selector.select()
        self._process_events(events)

    def _process_tasks(self, tasks):
        while tasks:
            self._run(tasks.pop(0))

    def _process_events(self, events):
        for key, mask in events:
            self._selector.unregister(key.fileobj)
            gen = key.data
            self._run(gen)

    def _run(self, gen):
        self._current_gen = gen  # Used as callback if wait_for() called during "next(gen)"
        try:
            next(gen)
        except StopIteration:  # Disconnected (returned, not yielded)
            pass

    def sock_accept(self, serv_sock):
        try:
            sock, addr = serv_sock.accept()  # Try
            sock.setblocking(False)
            return sock, addr
        except (BlockingIOError, InterruptedError):
            yield from self.wait_for(serv_sock)  # Go back to main loop until ready
            return (yield from self.sock_accept(serv_sock))  # Try again

    def sock_recv(self, sock, nbytes):
        try:
            return sock.recv(nbytes)  # Try
        except (BlockingIOError, InterruptedError):
            yield from self.wait_for(sock)  # Go back to main loop until ready
            return (yield from self.sock_recv(sock, nbytes))  # Try again

    def sock_sendall(self, sock, data):
        sock.send(data)

def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((host, port))
        serv_sock.listen(1)
        # sock.setblocking(False)
        loop = get_event_loop()
        while True:
            sock, addr = yield from loop.sock_accept(serv_sock)
            loop.create_task(handle_connection(sock, addr))

def handle_connection(sock, addr):
    print("Connected by", addr)
    while True:
        try:
            data = yield from loop.sock_recv(sock, 1024)
        except ConnectionError:
            print(f"Client suddenly closed while receiving")
            break
        print(f"Received {data} from: {addr}")
        if not data:
            break  # EOF - closed by client
        data = data.upper()
        print(f"Send: {data} to: {addr}")
        try:
            loop.sock_sendall(sock, data)  # Hope it won't block
        except ConnectionError:
            print(f"Client suddenly closed, cannot send")
            break
    sock.close()
    print("Disconnected by", addr)

HOST, PORT = "", 50007

if __name__ == "__main__":
    run(main(HOST, PORT))
```

Далее, во-вторых, переместим wait_for() внутрь sock_accept() и sock_recv(). Тем самым мы скроем детали реализации внутри SelectorLoop и избавим пользователя от необходимости помнить, что перед каждым блокирующим вызовом (loop.sock_accept() или loop.sock_recv()) нужно еще всегда вызывать ```yield loop.wait_for()```. Там мы попытаемся сразу выполнить accept() или recv() и только в случае неудачи вернемся (yield) в основной цикл. Для этого сокеты нужно сделать неблокирующими:

```python
class SelectorLoop:
	# ...
    def sock_accept(self, serv_sock):
        try:
            sock, addr = serv_sock.accept()
            sock.setblocking(False)
            return sock, addr
        except (BlockingIOError, InterruptedError):
            yield from self.wait_for(serv_sock)
            return (yield from self.sock_accept(serv_sock))

    def sock_recv(self, sock, nbytes):
        try:
            return sock.recv(nbytes)
        except (BlockingIOError, InterruptedError):
            yield from self.wait_for(sock)
            return (yield from self.sock_recv(sock, nbytes))

def main(host, port):
	with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
		serv_sock.bind((host, port))
		serv_sock.listen(1)
		serv_sock.setblocking(False)
		print("Server started")

		loop = get_event_loop()
		while True:
			sock, addr = yield from loop.sock_accept(serv_sock)
			loop.create_task(handle_connection(sock, addr))

def handle_connection(sock, addr):
    while True:
    	# ...
        data = yield from loop.sock_recv(sock, 1024)
    	# ...
```

Вот тут нам по-настоящему и пригодится yield from из [прошлой статьи](02_server_07.md). Мы помним, что если из gen1 вызывать yield from gen1, то в свойстве gen1.gi_yieldfrom будет ссылка на gen2. А если перед этим в gen2 был вызван yield from gen3, то gen2.gi_yieldfrom=gen3 и gen1.gi_yieldfrom.gi_yieldfrom=gen3. И так до бесконечности. Позже, когда gen1 снова попробуют итерировать — next(gen1) — то выполнение продолжится с самого последнего ненулевого элемента gi_yieldfrom во всей цепочке вложенностей. То есть с gen3 (`gen1.gi_yieldfrom.gi_yieldfrom`, потому что `gen1.gi_yieldfrom.gi_yieldfrom.gi_yieldfrom is None`).

Так в интерпретаторе Python реализована функция `next()`. Для этого и вводились в язык инструкция yield from и свойство gi_yieldfrom. Именно благодаря им управление программой может из любого уровня вложенности вернуться в основной цикл, а потом снова возобновить свою работу с того же места, с какого прервался. При этом нам достаточно всегда хранить ссылку только на самый первый генератор (gen1), а обо всем остальном позаботится сам Python.

## Переход к asyncio

Теперь наш движок для переключения сопрограмм стал неотличим от asyncio. И пользовательские функции main() и handle_connection() будут точно такими же, как если бы они были написаны сразу для asyncio (за исключением декоратора @asyncio.coroutine, но об этом ниже). Теперь мы можем убрать код нашего движка, а вместо него использовать стандартный asyncio:

```python
@asyncio.coroutine
def main(host, port):
	# ...
	sock, addr = yield from loop.sock_accept(serv_sock)
	# ...

@asyncio.coroutine
def handle_connection(sock, addr):
	# ...
	data = yield from loop.sock_recv(sock, 1024)
	# ...
	yield from loop.sock_sendall(sock, data)
	# ...

HOST, PORT = "", 50007

if __name__ == "__main__":
    asyncio.run(main(HOST, PORT))
```

Как видим, asyncio проверяет готовность сокетов на запись (selectors.EVENT_WRITE), поэтому перед вызовом loop.sock_sendall() добавляется yield from. Еще, с появлением asyncio было решено разграничить понятия генератора и сопрограммы (coroutine) с тем, чтобы в asyncio обрабатывать только сопрограммы и не обрабатывать генераторы. Главное, что делает декоратор @asyncio.coroutine, это устанавливает объекту генератора специальный флаг, что он теперь не генератор, а сопрограмма. Функция inspect.iscoroutine() должна возвращать для него отныне True, а inspect.isgenerator() — False. Еще с сопрограммами может использоваться только yield from, но не yield. Собственно, это и все отличия между генераторами и сопрограммами в Python. Нетрудно заметить, что они весьма формальные.

## Переход к async-await

Следующий шаг — заменить обозначение асинхронной функции (сопрограммы) с `@asyncio.coroutine` на `async`, а обозначение вызова сопрограммы с `yield from` на `await`. Предыдущие обозначения были не только неудобными, но и не вполне понятными. Они еще хранили на себе печать своего происхождения от генераторов (yield), тогда как условия изменились, и там, где они применяются, никто никаких генераторов не ожидает. Поэтому для тех, кто не знает всей истории сопрограмм в Python, не ясно, какая связь существует между ожиданием возврата значения из сопрограммы и инструкцией yield from.

```python
async def main(host, port):
	# ...
	sock, addr = await loop.sock_accept(serv_sock)
	# ...

async def handle_connection(sock, addr):
	# ...
	data = await loop.sock_recv(sock, 1024)
	# ...
	await loop.sock_sendall(sock, data)
	# ...

HOST, PORT = "", 50007

if __name__ == "__main__":
    asyncio.run(main(HOST, PORT))
```

Ключевые слова async и await — это всего лишь синтаксический сахар для декоратора coroutine и инструкции yield from. Просто так удобнее писать и понятнее читать. При этом старый синтаксис по-прежнему можно использовать, хоть его и запрещено смешивать с новым.

## Финальная версия

В конце концов, как и в случае с TCPServer, ForkingTCPServer и [ThreadingTCPServer](02_server_05.md#threads), в asyncio цикл приема новых соединений (`main()`) тоже был вынесен в стандартную библиотеку — в сопрограмму asyncio.start_server(). А использование клиентских сокетов напрямую (в handle_connection()) заменено на абстракции потоков чтения и записи: StreamReader и StreamWriter. Они скрывают некоторые особенности работы сокетов, предоставляя лаконичный и простой интерфейс (read(), write()).

Кроме того, использование этих оберток позволяет унифицировать работу с любыми потоками данных. Один и тот же код будет работать одинаково и для сокетов, и для файлов, и для любых других устройств ввода-вывода. Достаточно лишь подставить нужную реализацию StreamReader и StreamWriter. Пользовательский код при этом ничего даже не заметит.

```python
import asyncio

async def handle_connection(reader, writer):
    addr = writer.get_extra_info("peername")
    print("Connected by", addr)
    while True:
        # Receive
        try:
            data = await reader.read(1024)
        except ConnectionError:
            print(f"Client suddenly closed while receiving from {addr}")
            break
        if not data:
            break
        data = data.upper()
        try:
            writer.write(data)
        except ConnectionError:
            print(f"Client suddenly closed, cannot send")
            break
    writer.close()
    print("Disconnected by", addr)

async def main(host, port):
    server = await asyncio.start_server(handle_connection, host, port)
    async with server:
        await server.serve_forever()

HOST, PORT = "", 50007

if __name__ == "__main__":
    asyncio.run(main(HOST, PORT))
```

Как известно, инструкция with вызывает магический метод __enter__() в начале блока кода, который она оборачивает, и __exit__() — в конце этого блока. На случай, если в этих методах нужно вызвать сопрограмму (то есть использовать await), были созданы асинхронные их версии: __aenter__() и __aexit__(). Для них была добавлена и асинхронная версия with — async with.

Например, в asyncio базовый класс для сервера при выходе из блока with должен дождаться закрытия соединения. Это значит, что внутри __exit__() должен быть использован await. Поэтому мы вместо with и __exit__() должны использовать их асинхронные версии:

```python
async def main(host, port):
    server = await asyncio.start_server(handle_connection, host, port)
    async with server:
        await server.serve_forever()

class AbstractServer:
	# ...
    async def __aexit__(self, *exc):
        self.close()
        await self.wait_closed()
```

Вот мы и пришли к конечной версии простейшего сокет-сервера на Python. Мы опробовали самые разные варианты от синхронного кода с блокирующими сокетами, до использования потоков и процессов для одновременной обработки соединений, и убедились, что нет более быстрого решения — в разработке и исполнении кода — чем асинхронное программирование.

Но это был лишь первый шаг. [Далее](02_server_09.md) мы не его основе начнем строить реальные приложения,в процессе чего обнаружим, что существует куча функций, который переходит без изменения из приложения в приложение. Чтобы избежать примитивного копирования кода, все общие места вынесем в отдельную библиотеку, которая станет обобщенным каркасом для всех последующих приложений. Или другими словами — фреймворком. Он будет брать на себя все структурные и инфраструктурные моменты, благодаря чему мы сможем сосредоточиться исключительно на написании логики.

Подробнее:
[Асинхронность в программировании](https://tproger.ru/articles/asynchronous-programming/)
[Async IO in Python: A Complete Walkthrough](https://realpython.com/async-io-python/)

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/server_socket/v0/)

[< Назад](02_server_07.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](02_server_09.md)
