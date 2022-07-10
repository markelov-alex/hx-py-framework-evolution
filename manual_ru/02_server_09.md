# Эволюция игрового фреймворка. Сервер 9. Отправная точка

([Ранее]() мы рассмотрели пример простейшего эхо-сервера, реализованного [17-ю разными способами](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/server_socket/v0/). Сейчас наша задача — довести этот пример до простого и вполне себе боевого приложения, а затем и фреймворка.

Слово простой обычно трактуется как синоним неразвитого, недоделанного. Но его также можно понимать и по-другому — как законченный, совершенный, достигший уровня простоты. Ведь как известно, сложное сделать просто — сложно сделать простое. Мы начнем с первого определения и постараемся достичь второго.

Под совершенным мы будем понимать такой код, который:
1. делает то, что нужно (функциональность);
2. легко можно использовать повторно (универсальность);
3. понятен даже новичку (простота).

Все эти качества приобретаются постепенно в результате длительной и кропотливой работы, перемежающейся озарениями, которую в сжатом и существенном виде мы и предлагаем повторить.

Начнем мы с доводки [простейшего примера](02_server_09.md) до законченной боеспособной версии. В учебных целях в нем были опущены контроль целостности сообщений, их формат и прочие важные моменты, без которых реальное приложение немыслимо. Поэтому первым делом исправим эти недостатки.

## Разделение сообщений

Методы чтения socket.recv() и StreamReader.read() (обертка над socket.recv()) вернет столько байт, сколько есть в буфере, но не больше, чем мы запросим параметром nbytes. По сокетам пересылается сплошной поток байтов — без EOT-символа (End of Transmission) или другого какого-либо разделителя. Поэтому, чтобы знать, когда заканчивается одно сообщение и начинается другое, мы должны сами ввести один из способов разделения сообщений.

Для этого мы можем:

1. Завершать соединение (shut down) в конце каждого сообщения, как в HTTP, и тогда все полученные данные будут одним сообщением. Разделитель в таком случае — сам факт закрытия соединения. Способ не подходит, если нам нужно в любой момент иметь возможность посылать или получать сообщения с клиента, для чего нужно иметь постоянное соединение.

2. Делать сообщения фиксированной длины, известной и клиенту и серверу. Очень плохое, негибкое решение. В реальности у нас почти наверняка все сообщения будут разной длины, и тогда мы либо будем впустую нагружать канал нулевыми полями, либо придется ухищряться разбивать большие цельные блоки данных и распределять их между разными сообщениями.

3. Использовать определенный разделительный символ, который не будет встречаться в передаваемых данных. Например, нулевой байт \x00. Хорошо подходит для текстовых данных (ASCII, UTF-8), на основе которых обычно применяются форматы JSON, YML, XML. Но совершенно не подходит для бинарных протоколов, где может встретиться любой байт или любая последовательность байтов, которая может по ошибке быть принята за разделитель.

4. В первых нескольких байтах указывать длину сообщения. Универсальное решение, но применяется в основном только для бинарных протоколов. Для текстовых проще и очевиднее сделать с разделителем.

Первые два пункта мы отметаем сразу. А в случае с разделителем (3) мы не можем заранее знать сколько байтов нам нужно получить из буфера. Поэтому последнее сообщение часто может оказываться неполным. Хотя то же самое касается и всех остальных решений, так как send() не всегда отправляет все данные за один раз. Поэтому мы всегда должны это учитывать. Всякое неполное сообщение должно откладываться до следующего раза:

```python
async def handle_connection(reader, writer):
    print("+Connected")
	unparsed_bytes = b""
	while True:
		request_bytes = await reader.read(1024)
		request_bytes = unparsed_bytes + request_bytes
		request_bytes_list = request_bytes.split(b"\x00")
		unparsed_bytes = request_bytes_list.pop()
		# ...
```

## Сериализация и парсинг

Далее. В реальности нам понадобится решать задачи посложнее обычного перевода строки в верхний регистр. И обычных строк нам тоже недостаточно. Нам нужны числа, массивы, сложные объекты. Поэтому проще всего использовать один из стандартных форматов для кодирования объектов в строку (сериализация) и обратно (парсинг), вроде JSON. Так как большая часть этих объектов символизирует некое действие, приказ для программы, то будем называть их командами. Логика нашего приложения будет оперировать только такими командами-объектами. Всю остальную работу по переводу их в транспортабельный вид и обратно берет сервер:

```python
async def handle_connection(reader, writer):
    print("+Connected")
	# ...
    while True:
		request_bytes = await reader.read(1024)
		# ...
		request_str = request_bytes.decode("utf8")
		request_command = json.loads(request_str)
        response_command = handle_command(request_command)
        response_str = json.dumps(response_command)
        response_bytes = response_str.encode("utf8")
		writer.write(response_bytes)
    writer.close()
    print(f"-Disconnected")

def handle_command(command):
	# ...
```

JSON был выбран из-за простоты, экономичности и повсеместной распространенности. Вместо него можно взять любой другой формат или даже придумать собственный.

Например, разработать свой бинарный протокол. Это самый эффективный с точки зрения экономии трафика. Так, число 12000 в нем можно закодировать всего 2 байтами, вместо 5 в случае использования строк (JSON). Хотя если большая часть полей в передаваемых объектах нули, то выгоднее использовать строки, которые кодируют числа от 0 до 9 всего одним байтом.

Также, говоря о бинарных протоколах, нельзя пройти мимо проблемы разного формата двоичных данных на разных системах. Так двухбайтное число 1 на одних машинах может храниться как `01 00`, а на других как `00 01`. Обратный (Little-Endian — `01 00`) и прямой (Big-Endian — `00 01`) порядок байтов, соответственно. Для унификации был создан отдельный сетевой (Network) формат, а в библиотеки сокетов добавили функции для преобразования 16- и 32-битных целых чисел: htonl(), htons(), ntohl(), ntohs(), где n обозначает network, h - host, s - short, l - long. Если на данной системе порядок совпадает с сетевым, то функции не делают ничего.

Как бы там ни было, мы намерены так организовать программу, чтобы способ кодирования можно было менять по щелчку пальцев, без каких-либо изменений в остальном коде.

## Отсылка сообщений разным клиентам

В отличие от эхо-сервера, где каждое соединение существует само по себе, в реальных приложениях клиентское сообщение может инициировать посылку данных и другим соединениям. Собственно, для того сервер и нужен, чтобы информировать все клиенты об изменениях общего состояния приложения. Поэтому handle_command() должен не только возвращать ответную команду, но еще и как-то указывать, кому ее нужно отослать. Пока что будем различать только два направления: самому себе и всем. Чтобы можно было отослать всем, каждый клиентский сокет (в данном случае обертка вокруг сокета — StreamWriter) должен добавляться в список подключений writers при установлении соединения и удаляться — при разрыве.

```python
last_index = 0
writers = []

async def handle_connection(reader, writer):
    global last_index
    global writers
    writers.append(writer)
    last_index += 1
    i = last_index
    print("+Connected", i)
	# ...
	while True:
		# ...
		to_self_command, to_rest_command = handle_command(i, command)
		# ...
		if to_self_bytes:
			writer.write(to_self_bytes)
		if to_all_bytes:
			for w in writers:
				w.write(to_all_bytes)
    writers.remove(writer)
    writer.close()
    print(f"-Disconnected", i)
```

А чтобы внутри handle_command() отличать одно соединение от другого, каждому присваивается уникальный идентификатор равный порядковому номеру — i.

## Немедленная отправка сообщений

StreamWriter.write() заполняет данными буфер, который будет отправлен сразу или когда придет его очередь. А может вообще никогда не отправится. Поэтому, чтобы сообщения доходили вовремя, нужно явно вызывать функцию drain().

```python
writer.write(data_bytes)
await writer.drain()
```

## Сервер

Итоговый обработчик соединений, от которого можно отталкиваться в реальной работе будет выглядеть примерно так:

```python
last_index = 0
writers = []

async def handle_connection(reader, writer):
    global last_index
    global writers
    writers.append(writer)
    last_index += 1
    i = last_index
    print("+Connected")
    unparsed_bytes = b""
    while True:
    	# Receive
        try:
            request_bytes = await reader.read(1024)
        except ConnectionError:
            break
        if reader.at_eof():
            break  # Disconnected by client
        request_bytes = unparsed_bytes + request_bytes
        request_bytes_list = request_bytes.split(b"\x00")
        unparsed_bytes = request_bytes_list.pop()

		# Process
        for request_bytes in request_bytes_list:
            if not request_bytes:
                continue
            request = request_bytes.decode("utf8")
            print(" >> Received: {repr(request)}")
			try:
				command = json.loads(request)
				to_self_command, to_rest_command = handle_command(i, command)
			except Exception as e:
				print(f"[SERVER#{i}] Error while parsing or processing: {e}")
				to_self_command, to_rest_command = {"error": str(e)}, None
			self_response = json.dumps(to_self_command) if to_self_command else None
			all_response = json.dumps(to_rest_command) if to_rest_command else None
            print(f" << Send: {repr(self_response)} as self_response and commands: "
                  f"{repr(all_response)} to all {len(writers)} connections")
            if self_response:
                to_self_bytes = self_response.encode("utf8") + b"\x00"
                try:
                    writer.write(to_self_bytes)
                    await writer.drain()
                except ConnectionError:
                    pass  # Yet must send to others
            if all_response:
                to_all_bytes = all_response.encode("utf8") + b"\x00"
                for w in writers:
                    try:
                        w.write(to_all_bytes)
                        await w.drain()
                    except ConnectionError:
                        continue
    writers.remove(writer)
    writer.close()
    print(f"-Disconnected")

def handle_command(i, command):
	...
	return None, None
```

Клиент может разорвать соединение в любой момент, и тогда любой вызов read() или write() сгенерирует исключение ConnectionError (обычно ConnectionResetError). Поэтому, чтобы не нарушить логику выполнения программы, это исключение должно всегда обрабатываться. По тем же причинам добавили обработку всех исключений и на парсинг и обработку команд.

Код для запуска сервера не изменился:

```python
async def main(host, port):
    print(f"Start server: {host}:{port}")
    server = await asyncio.start_server(handle_connection, host, port)
    async with server:
        await server.serve_forever()

HOST, PORT = "", 5554
if __name__ == "__main__":
    asyncio.run(main(HOST, PORT))
```

Вот в сущности и все, что необходимо знать про сокеты и транспортировку сообщений. Дальше ничего нового на эту тему не скажем. Почитать побольше можно в [Socket Programming HOWTO (python.org)](https://docs.python.org/3/howto/sockets.html).

## Логика

Теперь нам осталось добавить, собственно, только логику приложения. Для этого специально выделена функция `handle_command()`.

Для примера возьмем самую простую, какую только можно придумать, функциональность — реализацию словаря ключ-значение с командами get, set и update. Она подходит не только для Dress-Up-игра, клиент к которым мы разрабатывали в [первой части](01_client_01.md), но и для многих других жанров, для которых нужно только хранить состояние текущей игры. Состояние будем хранить в простой глобальной переменной `storage`:

```python
storage = {}

def handle_command(i, command):
    global storage
    key = command.get("key")
    code = command.get("code")
    if code == "get":
		state = storage.get(key)
		return {"success": True, **command, "state": state}, None
	elif code == "set":
        state = command.get("state")
        storage[key] = state
        return {"success": True, **command}, None
    elif code == "update":
        index = command.get("index")
        value = command.get("value")
        if not isinstance(index, int) or not isinstance(value, int):
            return {"success": False, **command}, None
        state = storage.get(key)
        if state is None:
            storage[key] = state = []
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        return None, {"success": True, **command}
    return None, None
```

По сути приложение готово. По крайней мере оно функционально не изменится до самого конца руководства. Все остальное будет лишь непрерывным улучшением кода. И чтобы два раза не вставать, сделаем первое очень важное такое улучшение: отделим логику от сервера.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/server_socket/v1)

[< Назад](02_server_08.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](02_server_10.md)
