import asyncio
import json

# Add "../server_flask" directory to source paths in your IDE
from v7 import app

# Refactoring:
# - handle_connection() -> Server
# - handle_bytes() -> Application + Parser
# - handle_command() -> Controller + Logic + Service from app7
print("socket v3")


# handle_connection() -> Server

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
        self.writers = []

    def run(self):
        asyncio.run(self.main())

    async def main(self):
        print(f"Start server: {self.host}:{self.port}")
        server = await asyncio.start_server(self.handle_connection, self.host, self.port)
        async with server:
            await server.serve_forever()

    async def handle_connection(self, reader, writer):
        self.writers.append(writer)
        self.last_index += 1
        i = self.last_index

        print(f"[SERVER#{i}] +Connected.")
        unparsed_bytes = b""
        while True:
            # Receive request
            print(f"[SERVER#{i}] (Receiving from client...)")
            try:
                request_bytes = await reader.read(1024)
            except ConnectionError:
                break
            if reader.at_eof():
                print(f"[SERVER#{i}] EOF. Connection closed")
                break

            request_bytes = unparsed_bytes + request_bytes
            print(f"[SERVER#{i}] >> Received: {repr(request_bytes)}")

            # Handle
            to_self_bytes, to_all_bytes, unparsed_bytes = \
                self.application.handle_bytes(i, request_bytes)

            # Send
            print(f"[SERVER#{i}] << Send: {repr(to_self_bytes)} to current and commands: "
                  f"{repr(to_all_bytes)} to all {len(self.writers)} connections")
            if to_self_bytes:
                try:
                    writer.write(to_self_bytes)
                    await writer.drain()
                except ConnectionError:
                    pass  # Yet must send to others
            if to_all_bytes:
                for w in self.writers:
                    try:
                        w.write(to_all_bytes)
                        await w.drain()
                    except ConnectionError:
                        continue

        print(f"[SERVER#{i}] -Connection close")
        self.writers.remove(writer)
        writer.close()
        try:
            await writer.wait_closed()
        except ConnectionError:
            pass


# handle_bytes() -> Application + Parser

class SocketApplication:
    def __init__(self, parser, default_controller, controller_by_key=None) -> None:
        super().__init__()
        self.parser = parser
        self.default_controller = default_controller
        self.controller_by_key = controller_by_key or {}

    def handle_bytes(self, i, request_bytes):
        # Crossdomain request for Flash clients
        if request_bytes == b"<policy-file-request/>\x00":
            return b"<cross-domain-policy>" \
                   b'<allow-access-from domain="*" to-ports="*"/>' \
                   b"</cross-domain-policy>\x00", None, b""

        unparsed_bytes = b""
        try:
            # Parse
            commands, unparsed_bytes = self.parser.parse(request_bytes)
            # Handle
            to_self_commands, to_all_commands = self.handle_commands(commands)
        except Exception as e:
            print(f"[SERVER#{i}] Error while parsing or handling: {request_bytes} {e}")
            to_self_commands, to_all_commands = {"error": str(e)}, None
        # Serialize
        to_self_bytes = self.parser.serialize(to_self_commands)
        to_all_bytes = self.parser.serialize(to_all_commands)
        return to_self_bytes, to_all_bytes, unparsed_bytes

    def handle_commands(self, commands):
        result_self, result_all = [], []
        # Handle
        for command in commands:
            key = command.get("key")
            controller = self.controller_by_key.get(key, self.default_controller)
            if controller:
                controller.handle_command(command, result_self, result_all)
        # Add version (temp)
        for c in result_self:
            c["version"] = "v6"
        for c in result_all:
            c["version"] = "v6"
        return result_self, result_all


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


# handle_command() -> Controller + Logic + Service from app7

class MyController:

    def __init__(self) -> None:
        super().__init__()
        self.controller = app.MyController()

    def handle_command(self, command, result_self, result_all):
        response = self.controller.handle_command(command)
        code = command.get("code")
        if code == "load" or code == "get":
            result_self.append(response)
        else:
            result_all.append(response)


HOST, PORT = "", 5554
if __name__ == "__main__":
    app = SocketApplication(JSONParser(), MyController())
    server = SocketServer(app, HOST, PORT)
    server.run()
