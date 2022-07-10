# Эволюция игрового фреймворка. Сервер 14. Внутренние и отложенные команды

Жизненный цикл приложения на данный момент очень простой: получаются команды, они обрабатываются, и результат отсылается назад. Если команда не была получена, то нечего и отсылать. Ясно, что для серьезных сложных приложений этого мало. Практически в каждой игре должен быть внутренний цикл работы или хотя бы таймер, по которому игра сама могла бы нужный момент времени посылать команды — по собственному почину, без запроса пользователя. Должна существовать возможность приложению самому инициировать события.

Так как все события у нас — это команды, то и для реализации внутреннего цикла приложения нет смысла отступать от общей канвы. Команды для этого очень даже подходят. А раз они не должны быть отосланы клиентам, то и индексы им не нужны. Вместо индексов будем использовать None. Так и будем отличать внутренние команды от внешних:

```python
class SocketApplication:
	# ...
    def handle_commands(self, index, commands):
        result = []
        # Handle
        for command in commands:
            key = escape(command.get("key"))
            controller = self.controller_by_key.get(key, self.default_controller)
            if controller:
                controller.handle_command(self.storage, index, command, result)
        # Handle internal or enqueue if deferred
        for indexes, commands in result:
            if indexes is None:
                result += self.handle_internal(commands)
        return result

    def handle_internal(self, commands):
        result = self.handle_commands(None, commands)
        for indexes, c in result:
            if indexes is None:
                result += self.handle_internal(c)
        return result
```

Мы видим, что внутренние команды генерируются контроллерами наравне с обычными внешними и добавляются в тот же массив result. Для фильтрации внутренних команд от внешних и их исполнения создан отдельный метод — handle_internal(). Исполняются же они так же как внешние — в handle_commands() — за тем единственным исключением, что в параметре index передается None. В результате функции handle_commands() и handle_internal() вызывают друг друга рекурсивно до тех пор, пока контроллеры не возвратят результат без внутренних команд. То есть, когда в результате будут команды, предназначенные только для отправки клиентам.

Теперь, имея функционал внутренних команд, можно добавить к ним исполнение по периоду времени и получим готовый внутренний цикл программы. Достаточно вызвать, например, `handle_command(None, {"code": "check_game_end", "period_ms": 1000})` и каждую секунду будет производится проверка на окончание игры.

А раз мы сделали периодическую обработку команды, то автоматически получаем и частный случай периодической обработки — одноразовую отложенную обработку команды. Для этого вместо period_ms будем использовать after_ms. И то и другое реализуется установкой абсолютного времени исполнения команды — свойства at_ms = current_time_ms + period/after_ms. За точку отсчета абсолютного времени возьмем время запуска приложения. Хотя можно использовать и обычный [Unix timestamp](https://ru.wikipedia.org/wiki/Unix-%D0%B2%D1%80%D0%B5%D0%BC%D1%8F), если нужно.

В качестве меры времени будем везде использовать миллисекунды. Почему именно миллисекунды? Во-первых, деление на целые секунды — это мало, а поэтому придется использовать числа с плавающей запятой. Это по многим вполне понятным причинам нежелательно. Производить вычисления с целыми числами удобнее. Во-вторых, значения меньше 1 миллисекунды не имеют практического значения: не всегда можно обеспечить такую точность и производительность, да это никто и не заметит. А так как секунды — это слишком много, а микросекунды — слишком мало, то миллисекунды остаются хорошим выбором.

Отложенные команды реализуются с помощью очереди команд, отсортированной по времени их будущего выполнения. Отсортированную — потому что нам проще один раз пройтись по очереди во время добавляения, чем потом каждый раз проходить всю очередь во время поиска готовых к исполнению команд. В отсортированной очереди перебор команд прекращается с первым же неподходящим элементом.

```python
class SocketApplication:
    @property
    def time_ms(self):
        # Current app time
        return int(time.time() - self.storage.get("start_app_time_ms") * 1000)

    def __init__(self, default_controller, controller_by_key=None) -> None:
        super().__init__()
        self.default_controller = default_controller
        self.controller_by_key = controller_by_key or {}
        self.storage = {"start_app_time_ms": time.time()}
        self.command_queue = self.storage["command_queue"] = []
	# ...
    def handle_internal(self, commands):
        # Enqueue commands with time
        handle_now_list = []
        for command in commands:
            # (Convert after_ms, period_ms to at_ms)
            at_ms = command.get("at_ms")
            if at_ms is None:
                after_ms = command.get("after_ms")
                if after_ms is not None and after_ms >= 0:
                    at_ms = command["at_ms"] = self.time_ms + after_ms
                else:
                    # (Note: To handle periodical command first time immediately,
                    #  set also after_ms=0 or at_ms=0)
                    period_ms = command.get("period_ms")
                    if period_ms is not None and period_ms >= 0:
                        at_ms = command["at_ms"] = self.time_ms + period_ms
            # (If command doesn't have at_ms, it can not be enqueued)
            if at_ms is not None:
                # (Insert)
                index = 0
                for c in self.command_queue:
                    c_at_ms = c.get("at_ms")
                    if c_at_ms and c_at_ms < at_ms:
                        break
                    index += 1
                self.command_queue.insert(index, command)
            else:
                # (To handle)
                handle_now_list.append(command)
        # Handle other
        result = self.handle_commands(None, handle_now_list) if handle_now_list else []
        for indexes, c in result:
            if indexes is None:
                result += self.handle_internal(c)
        return result

    def handle_deferred(self):
        commands = []
        periodical_commands = []
        # Find commands which time has come
        for command in self.command_queue.copy():
            self.command_queue.remove(command)
            at_ms = command.get("at_ms")
            if at_ms is None or at_ms < 0:
                # Note: All commands in queue should have at_ms.
                # If not, it's same as being marked deleted.
                continue
            elif at_ms > self.time_ms:
                # No more commands to handle
                break
            else:
                # Handle
                commands.append(command)
                # Check periodical
                period_ms = command.get("period_ms")
                if period_ms is not None and period_ms > 0:
                    # command["at_ms"] = None  # Ok, but slower than following
                    command["at_ms"] = self.time_ms + period_ms
                    periodical_commands.append(command)
        # Handle
        result = self.handle_commands(None, commands)
        # Enqueue periodical back
        result += self.handle_internal(periodical_commands)
        return result
```

Видно, что after_ms и period_ms используются только для того, чтобы вычислить at_ms, который в действительности единственный только и используется системой. Перед обработкой команда удаляется из очереди, но если у нее установлено свойство period_ms, то она вновь туда добавится вызовом handle_internal().

То, что команды и время старта приложения хранятся в общем состоянии приложения storage, позволяет нам сохранять и загружать состояние в файл, перезапускать сервер и возобновлять его работу с того же места. Никакие запланированные на будущее действия и события не потеряются — все будет выполнено.

Метод handle_deferred() вызывается из основного цикла сервера (main()) с относительно небольшим интервалом времени. Он должен быть не слишком большим, чтобы можно было генерировать события через доли секунды, и не слишком маленьким, чтобы не нагружать процессор лишними проверками очереди. Пожалуй, интервал в 0.1 секунды вполне подойдет.

```python
class SocketServer:
	# ...
    async def main(self):
        print(f"Start server: {self.host}:{self.port}")
        server = await asyncio.start_server(self.handle_connection, self.host, self.port)
        async with server:
			self.is_running = True
			while self.is_running:
				result = self.application.handle_deferred()
				self.send(result)
				await asyncio.sleep(.1)
```

Результат выполнения handle_deferred() также отправляется клиентам следующим за ним вызовом send(result). Это уже четвертый вызов send() в нашем фреймворке. Первый — после handle_bytes() — срабатывал непосредственно после обработки клиентских команд, следующие два — после on_connect() и on_disconnect() — после изменений в подключении. На этот раз отправка сообщений срабатывает не как реакция на действия пользователей, а по таймеру. То есть инициируется самим приложением.

Вот и все про сокет сервер. В [следующем материале](02_server_15.md) мы еще покажем, что данный фреймворк можно использовать и для других типов серверов — в частности HTTP-сервера. После чего, можно переходить непосредственно к использованию фреймворка в реализации разных жанров и мета-геймплея.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/server_socket/v6/)

[< Назад](02_server_13.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](02_server_15.md)
