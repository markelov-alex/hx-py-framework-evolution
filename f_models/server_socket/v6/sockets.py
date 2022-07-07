import asyncio
import json
import time

# Add "../server_flask" directory to source paths in your IDE
from v7.app import FileService


# Internal commands, ProtocolController

# Framework

class SocketServer:
    # Settings
    host = ""
    port = 5555

    def __init__(self, parser, application, host=None, port=None):
        url_parts = host.split(":") if host else None
        if url_parts:
            self.host = url_parts[0]
            self.port = port if port else (
                int(url_parts[1]) if len(url_parts) > 1 else self.port)
        self.parser = parser
        self.application = application
        self.last_index = 0
        self.writer_by_index = {}
        self.is_running = False

    def run(self):
        asyncio.run(self.main())

    async def main(self):
        print(f"Start server: {self.host}:{self.port}")
        server = await asyncio.start_server(self.handle_connection, self.host, self.port)
        async with server:
            self.is_running = True
            while self.is_running:
                result = self.application.handle_deferred()
                if result:
                    await self.send(result)
                await asyncio.sleep(.1)

    async def handle_connection(self, reader, writer):
        self.last_index += 1
        index = self.last_index
        self.writer_by_index[index] = writer

        print(f"[SERVER#{index}] +Connected.")
        result = []
        await self.application.on_connect(index, result)
        await self.send(result)
        unparsed_bytes = b""
        while True:
            # Receive request
            print(f"[SERVER#{index}] (Receiving from client...)")
            try:
                request_bytes = await reader.read(1024)
            except ConnectionError:
                break
            if reader.at_eof():
                print(f"[SERVER#{index}] EOF. Connection closed")
                break

            request_bytes = unparsed_bytes + request_bytes
            print(f"[SERVER#{index}] >> Received: {repr(request_bytes)}")

            # Handle
            result, unparsed_bytes = await self.handle_bytes(index, request_bytes)

            # Send response
            print(f"[SERVER#{index}] << Send: {repr(result)}")
            await self.send(result)

        print(f"[SERVER#{index}] -Connection close")
        result = []
        await self.application.on_disconnect(index, result)
        await self.send(result)
        del self.writer_by_index[index]
        writer.close()
        try:
            await writer.wait_closed()
        except ConnectionError:
            pass

    async def handle_bytes(self, index, request_bytes):
        # Crossdomain request for Flash clients
        if request_bytes == b"<policy-file-request/>\x00":
            return [([index], b"<cross-domain-policy>"
                              b'<allow-access-from domain="*" to-ports="*"/>'
                              b"</cross-domain-policy>\x00")], b""

        unparsed_bytes = b""
        try:
            # Parse
            commands, unparsed_bytes = self.parser.parse(request_bytes)
            # Handle
            result = await self.application.handle_commands(index, commands)
        except Exception as e:
            print(f"[SERVER#{index}] Error while parsing or handling: {request_bytes} {e}")
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
    @property
    def time_ms(self):
        # Current app time
        return int(time.time() - self.storage.get("start_app_time_ms") * 1000)

    def __init__(self, default_controller, controller_by_key=None) -> None:
        super().__init__()
        self.default_controller = default_controller
        self.controller_by_key = controller_by_key or {}
        self.storage = {}
        self.storage["start_app_time_ms"] = time.time()
        self.command_queue = self.storage["command_queue"] = []

    async def handle_commands(self, index, commands):
        result = []
        # Handle
        for command in commands:
            key = command.get("key")
            controller = self.controller_by_key.get(key, self.default_controller)
            if controller:
                await controller.handle_command(self.storage, index, command, result)
        # Handle internal or enqueue if deferred
        for indexes, commands in result:
            if indexes is None:
                result += await self.handle_internal(commands)
            # Add version (temp)
            for c in commands:
                c["version"] = "v6"
        return result

    async def handle_internal(self, commands):
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
        result = await self.handle_commands(None, handle_now_list) if handle_now_list else []
        for indexes, c in result:
            if indexes is None:
                result += await self.handle_internal(c)
        return result

    async def handle_deferred(self):
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
        result = await self.handle_commands(None, commands)
        # Enqueue periodical back
        result += await self.handle_internal(periodical_commands)
        return result

    async def on_connect(self, index, result):
        if self.default_controller:
            await self.default_controller.on_connect(self.storage, index, result)

    async def on_disconnect(self, index, result):
        if self.default_controller:
            await self.default_controller.on_disconnect(self.storage, index, result)


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


# Custom

# (Controller: Commands + Service + Model)

class MyProtocolController:
    # State
    room = None

    async def on_connect(self, storage, index, result):
        await self.add(storage, index)

    async def on_disconnect(self, storage, index, result):
        await self.remove(storage, index)

    async def handle_command(self, storage, index, command, result):
        code = command.get("code")
        key = command.get("key")
        if code == "goto":
            success = await self.goto(storage, index, key)
            result.append(([index], [{**command, "success": success}]))
        elif code == "load" or code == "get":
            state = await self.load(key)
            result.append(([index], [{**command, "success": True, "state": state}]))
        elif code == "save" or code == "set":
            state = command.get("state")
            success = await self.save(key, state)
            indexes = self.room.get_current_indexes_by_index(storage, index)
            result.append((indexes, [{**command, "success": success}]))
        elif code == "update":
            index = command.get("index")
            value = command.get("value")
            success = await self.update(key, index, value)
            indexes = self.room.get_current_indexes_by_index(storage, index)
            result.append((indexes, [{**command, "success": success}]))

    async def add(self, storage, index):
        pass

    async def remove(self, storage, index):
        pass

    async def goto(self, storage, index, key):
        pass

    async def load(self, key):
        pass

    async def save(self, key, state):
        pass

    async def update(self, key, index, value):
        pass


class MyController:
    # Settings
    service_factory = lambda self: FileService("../data/save_")

    def __init__(self) -> None:
        super().__init__()
        self.service = self.service_factory()
        self.room = RoomModel()
        self.model = MyModel()

    async def add(self, storage, index):
        self.room.add_index(storage, index)

    async def remove(self, storage, index):
        self.room.remove_index(storage, index)

    async def goto(self, storage, index, key):
        success = self.room.goto(storage, index, key)
        return success

    async def load(self, key):
        state = self.service.load(key)
        # todo state = await self.service.load(key)
        return state

    async def save(self, key, state):
        success = self.service.save(key, state) if state is not None else False
        # todo success = await self.service.save(key, state) if state is not None else False
        return success

    async def update(self, key, index, value):
        state = self.service.load(key)
        # todo state = await self.service.load(key)
        success = self.model.update(state, index, value)
        if success:
            success = self.service.save(key, state)
            # todo success = await self.service.save(key, state)
        return success


# (Domain Model)

class RoomModel:
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
        if index in storage:
            self.goto(storage, index, None)
            del storage[index]

    def goto(self, storage, index, key):
        if storage is None:
            return False
        # Remove from previous
        player = storage.get(index)
        if not player:
            player = storage[index] = {}
        prev_key = player.get("key") if player else None
        if prev_key == key:
            # Go to same
            return False
        prev_room = storage.get(prev_key) if prev_key else None
        prev_indexes = prev_room.get("indexes") if prev_room else None
        if prev_indexes and index in prev_indexes:
            prev_indexes.remove(index)
        # Add to new
        if not key:
            return False
        player["key"] = key
        room = storage.get(key) if key else None
        if room is None:
            room = storage[key] = {}
        indexes = room.get("indexes")
        if indexes is None:
            indexes = room["indexes"] = []
        if index not in indexes:
            indexes.append(index)
        return True

    def get_current_indexes_by_index(self, storage, index):
        if not storage:
            return [index]
        player = storage.get(index)
        key = player.get("key") if player else None
        room = storage.get(key) if key else None
        # (All in the room or all connected)
        return room.get("indexes") if room else storage.get("indexes")


class MyModel:
    def update(self, state, index, value):
        if not isinstance(index, int) or not isinstance(value, int):
            return False
        if state is None:
            state = []
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        return True


HOST, PORT = "", 5554
if __name__ == "__main__":
    app = SocketApplication(MyController())
    server = SocketServer(JSONParser(), app, HOST, PORT)
    server.run()
