# Эволюция игрового фреймворка. Сервер 13. Доводка сервера

После того, как мы создали фреймворк и разработали методику написания кастомной логики для него, нам остается еще сделать несколько усовершенствований до финальной версии.

## Различение подключений

Главное, что нужно сделать — это реализовать возможность отсылать любое сообщение любому пользователю, тогда как сейчас мы можем отсылать команды или только себе, или сразу всем.

В реальных приложениях все пространство разбивается на комнаты, между которыми распределяются пользователи. Поэтому, например, нет смысла отсылать данные о состоянии одной игры пользователям из другой. Они будут просто игнорировать сообщения из чужой игры.

Но и в пределах одного помещения может возникнуть необходимость различать пользователей. Например, при раздаче карт в покере каждый должен видеть только свои карты и не знать о картах соседей. А значит, для каждого пользователя должна быть подготовлена своя персональная версия команды. И тут нельзя рассчитывать, что клиент сам скроет нужные данные. Карты должны быть скрыты уже в получаемых сообщения от сервера, иначе пользователь может настроить один раз [сниффер](https://ru.wikipedia.org/wiki/%D0%90%D0%BD%D0%B0%D0%BB%D0%B8%D0%B7%D0%B0%D1%82%D0%BE%D1%80_%D1%82%D1%80%D0%B0%D1%84%D0%B8%D0%BA%D0%B0) (анализатор трафика) и потом все время выигрывать.

Поэтому уберем списки команд result_self, result_all, и добавим один массив result, каждый элемент которого будет пара (кортеж): список индексов соединений + список команд:

```python
class SocketServer:
    # ...
    async def handle_connection(self, reader, writer):
        # ...
        while True:
            # Receive request
            try:
                request_bytes = await reader.read(1024)
            except ConnectionError:
                break
            if reader.at_eof():  # if not request_bytes:  # Same
                print(f"[SERVER#{index}] EOF. Connection closed")
                break
            print(f"[SERVER#{index}] >> Received: {repr(request_bytes)}")
            # Handle
            result, unparsed_bytes = self.application.handle_bytes(index, request_bytes)
            # Send response
            print(f"[SERVER#{index}] << Send: {repr(result)}")
            await self.send(result)
        # ...

    async def send(self, result):
        if not result:
            return
        for indexes, response_bytes in result:
            for i in indexes:
                writer = self.writer_by_index.get(i)
                if writer:
                    writer.write(response_bytes)
                    await writer.drain()

class SocketApplication:
    def handle_bytes(self, index, request_bytes):
        unparsed_bytes = b""
        try:
            # Parse
            commands, unparsed_bytes = self.parser.parse(request_bytes)
            # Handle
            result = self.handle_commands(index, commands)
        except Exception as e:
            result = [([index], [{"error": str(e)}])]
        # Serialize
        result = [(indexes, self.parser.serialize(commands))
                  for indexes, commands in result]
        return result, unparsed_bytes

    def handle_commands(self, index, commands):
        result = []
        # Handle
        for command in commands:
            key = escape(command.get("key"))
            controller = self.controller_by_key.get(key, self.default_controller)
            if controller:
                controller.handle_command(self.storage, index, command, result)
        return result
```

Выше приведенный метод send() написан неудачно: сообщение следующему пользователю начнет отсылаться только тогда, когда отсылка предыдущему закончится. То есть следующий writer.write() выполнится только после того, как закончит выполняться предыдущий writer.drain(). Изменим код так, чтобы сначала всем разом отослать, и только потом всех разом ждать:

```python
    async def send(self, result):
        if not result:
            return
        wait_writers = []
        for indexes, response_bytes in result:
            for i in indexes:
                writer = self.writer_by_index.get(i)
                if writer:
                    try:
                        writer.write(response_bytes)
                        wait_writers.append(writer)
                    except ConnectionError:
                        continue
        await asyncio.gather(writer.drain() for writer in wait_writers)
```

Получилось вполне универсальное решение. Нам не нужно добавлять новый result_xxx массив на новый случай, а наоборот, все result_xxx массивы сократили до одного result, который подходит для всех возможных случаев.

Соответствующие изменения остается внести еще в контроллеры. А так как result используется только в протокольном контроллере, то задача упрощается:

```python
class MyProtocolController:
    def handle_command(self, storage, index, command, result):
        code = command.get("code")
        key = command.get("key")
        all_indexes = storage.get("indexes")
        if code == "save" or code == "set":
            state = command.get("state")
            success = self.save(key, state)
			result.append((all_indexes, {**command, "success": success}))
        elif code == "load" or code == "get":
        	state = self.load(key)
			result.append(([index], {**command, "success": True, "state": state}))
        elif code == "update":
            index = command.get("index")
            value = command.get("value")
            success = self.update(key, index, value)
			result.append((all_indexes, {**command, "success": success}))

    def save(self, key, state):
		pass

    def load(self, key):
		pass

    def update(self, key, index, value):
    	pass
```

## On connect/disconnect. Перенос сериализации в метод send

Второе усовершенствование, которое необходимо сделать — это добавление возможности реагировать на установление и разрыв соединения с клиентом. Например, можно послать приветственную команду с информацией о сервере при подключении и удалить данные о пользователе при его отключении. Для этого в контроллер добавим методы on_connect() и on_disconnect(), которые будут вызываться из Application, а инициироваться вызов будет в SocketServer:

```python
class SocketServer:
    def __init__(self, parser, application, host=None, port=None):
    	# ...
    # ...
    async def handle_connection(self, reader, writer):
        self.last_index += 1
        index = self.last_index
        self.writer_by_index[index] = writer
        print(f"[SERVER#{index}] +Connected")
        result = []
        self.application.on_connect(index, result)
        await self.send(result)
        unparsed_bytes = b""
        while True:
            # Receive
            try:
                request_bytes = await reader.read(1024)
            except ConnectionError:
                break
            if reader.at_eof():
                print(f"[SERVER#{index}] EOF. Connection closed")
                break
            request_bytes = unparsed_bytes + request_bytes
            # Handle
            result, unparsed_bytes = self.handle_bytes(index, request_bytes)
            # Send response
            await self.send(result)
        print(f"[SERVER#{index}] -Disconnected")
        result = []
        self.application.on_disconnect(index, result)
        await self.send(result)
        del self.writer_by_index[index]
        writer.close()

    # Move serialization to SocketServer.send()
    def handle_bytes(self, index, request_bytes):
        unparsed_bytes = b""
        try:
            # Parse
            commands, unparsed_bytes = self.parser.parse(request_bytes)
            # Handle
            result = self.application.handle_commands(index, commands)
        except Exception as e:
            result = [([index], [{"error": str(e)}])]
        return result, unparsed_bytes

    async def send(self, result):
        if not result:
            return
        # Serialize
        result = [(indexes, self.parser.serialize(commands))
                  for indexes, commands in result]
        # Send
        wait_writers = []
        for indexes, response_bytes in result:
            for i in indexes:
                writer = self.writer_by_index.get(i)
                if writer:
                    try:
                        writer.write(response_bytes)
                        wait_writers.append(writer)
                    except ConnectionError:
                        continue
        await asyncio.gather(writer.drain() for writer in wait_writers)

class SocketApplication:
	# ...
    def on_connect(self, index, result):
        if self.default_controller:
            self.default_controller.on_connect(self.storage, index)

    def on_disconnect(self, index, result):
        if self.default_controller:
            self.default_controller.on_disconnect(self.storage, index)

class MyProtocolController:
    # ...
    def on_connect(self, storage, index, result):
        self.add(storage, index)

    def on_disconnect(self, storage, index, result):
        self.remove(storage, index)

    def add(self, storage, index):
		pass

    def remove(self, storage, index):
		pass

class MyController(MyProtocolController):
    # ...
    def add(self, storage, index):
        self.model.add_index(storage, index)

    def remove(self, storage, index):
        self.model.remove_index(storage, index)

class MyModel:
    # ...
    def add_index(self, storage, index):
        indexes = storage.get("indexes")
        if indexes is None:
            storage["indexes"] = indexes = []
        indexes.append(index)

    def remove_index(self, storage, index):
        indexes = storage.get("indexes")
        if indexes is None:
            storage["indexes"] = indexes = []
        if index in indexes:
            indexes.remove(index)

HOST, PORT = "", 5554
if __name__ == "__main__":
    app = SocketApplication(MyController())
    server = SocketServer(JSONParser(), app, HOST, PORT)
    server.run()
```

Раньше у нас был только один вызов send() — из handle_bytes() — поэтому нас не особо заботило, где разместить сериализацию данных для отправки. Мы разместили ее там же, где и парсинг принятых данных — в handle_bytes(). Это выглядело логичным: налицо был полный цикл обработки данных — парсинг, обработка, сериализация.

Но теперь, когда у нас уже есть три вызова send(), а скоро будет еще один, код сериализации приходится дублировать для каждого из них. Дублирование — зло, а потому мы перенесли сериализацию прямо в send(). И так как send() находится в SocketServer, то туда же пришлось перенести и парсер (из Application), а вслед за ним и handle_bytes(). В результате Application теперь оперирует только командами. А сообщениями и их форматом при транспортировке заведует Server. Что в общем-то очень логично и правильно.

Итак, в данном разделе мы научились различать отдельные соединения при отсылке, а также выполнять действия и отсылать команды при установлении и разрыве соединения. Все изменения реализовывались главным образом в классе Server. В следующий раз мы больше будем обращаться к Application, ведь речь пойдет о командах.

[Исходники](https://gitlab.com/markelov-alex/hx-py-framework-evolution/-/tree/main/f_models/server_socket/v4/)

[< Назад](02_server_12.md)  |  [Начало](00_intro_01.md)  |  [Вперед >](02_server_14.md)
