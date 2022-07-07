import asyncio
import json

# Add "../server_flask" directory to source paths in your IDE
from v7.app import FileService


# Move to DDD

# Framework

class SocketServer:
    # Settings
    host = ""
    port = 5555

    def __init__(self, application, host=None, port=None):
        url_parts = host.split(":") if host else None
        if url_parts:
            self.host = url_parts[0]
            self.port = port if port else (
                int(url_parts[1]) if len(url_parts) > 1 else self.port)
        self.application = application
        self.last_index = 0
        self.writer_by_index = {}

    def run(self):
        asyncio.run(self.main())

    async def main(self):
        print(f"Start server: {self.host}:{self.port}")
        server = await asyncio.start_server(self.handle_connection, self.host, self.port)
        async with server:
            await server.serve_forever()

    async def handle_connection(self, reader, writer):
        self.last_index += 1
        index = self.last_index
        self.writer_by_index[index] = writer

        print(f"[SERVER#{index}] +Connected.")
        result = []
        self.application.on_connect(index, result)
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
            result, unparsed_bytes = self.application.handle_bytes(index, request_bytes)

            # Send response
            print(f"[SERVER#{index}] << Send: {repr(result)}")
            await self.send(result)

        print(f"[SERVER#{index}] -Connection close")
        result = []
        self.application.on_disconnect(index, result)
        await self.send(result)
        del self.writer_by_index[index]
        writer.close()
        try:
            await writer.wait_closed()
        except ConnectionError:
            pass

    async def send(self, result):
        if not result:
            return
        for indexes, response_bytes in result:
            for i in indexes:
                writer = self.writer_by_index.get(i)
                if writer:
                    try:
                        writer.write(response_bytes)
                        await writer.drain()
                    except ConnectionError:
                        continue


class SocketApplication:
    def __init__(self, parser, default_controller, controller_by_key=None) -> None:
        super().__init__()
        self.parser = parser
        self.default_controller = default_controller
        self.controller_by_key = controller_by_key or {}
        self.storage = {}

    def handle_bytes(self, index, request_bytes):
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
            result = self.handle_commands(index, commands)
        except Exception as e:
            print(f"[SERVER#{index}] Error while parsing or handling: {request_bytes} {e}")
            result = [([index], [{"error": str(e)}])]
        # Serialize
        result = [(indexes, self.parser.serialize(commands))
                  for indexes, commands in result]
        return result, unparsed_bytes

    def handle_commands(self, index, commands):
        result = []
        # Handle
        for command in commands:
            key = command.get("key")
            controller = self.controller_by_key.get(key, self.default_controller)
            if controller:
                controller.handle_command(self.storage, index, command, result)
        # Add version (temp)
        for indexes, commands in result:
            for c in commands:
                c["version"] = "v6"
        return result

    def on_connect(self, index, result):
        if self.default_controller:
            self.default_controller.on_connect(self.storage, index, result)

    def on_disconnect(self, index, result):
        if self.default_controller:
            self.default_controller.on_disconnect(self.storage, index, result)


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

class MyController:
    # Settings
    service_factory = lambda self: FileService("../data/save_")

    def __init__(self) -> None:
        super().__init__()
        self.service = self.service_factory()
        self.room = RoomModel()
        self.model = MyModel()

    def on_connect(self, storage, index, result):
        self.room.add_index(storage, index)

    def on_disconnect(self, storage, index, result):
        self.room.remove_index(storage, index)

    def handle_command(self, storage, index, command, result=None):
        if result is None:
            result = []
        code = command.get("code")
        key = command.get("key")
        if code == "goto":
            success = self.room.goto(storage, index, key)
            result.append(([index], [{**command, "success": success}]))
        elif code == "load" or code == "get":
            state = self.service.load(key)
            result.append(([index], [{**command, "success": True, "state": state}]))
        elif code == "save" or code == "set":
            state = command.get("state")
            success = state is not None
            if success:
                self.service.save(key, state)
            indexes = self.room.get_current_indexes_by_index(storage, index)
            result.append((indexes, [{**command, "success": success}]))
        elif code == "update":
            state = self.service.load(key)
            index = command.get("index")
            value = command.get("value")
            success = self.model.update(state, index, value)
            indexes = self.room.get_current_indexes_by_index(storage, index)
            if success:
                success = self.service.save(key, state)
            result.append((indexes, [{**command, "success": success}]))
        return result


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
    app = SocketApplication(JSONParser(), MyController())
    server = SocketServer(app, HOST, PORT)
    server.run()
