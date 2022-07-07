import asyncio


# Changes:
#  - create Server class for convenient configuring, extending and
#  using common server logic,
#  - move split(b"\x00") and adding b"\x00" to parser,
#  - parsers now return also unparsed_bytes.
class Server:
    # Settings
    default_host = None
    default_port = None
    game_factory = None
    # State
    game = None

    def __init__(self, host=None, port=None, game_or_factory=None) -> None:
        super().__init__()

        if host is not None:
            self.default_host = host
        if port is not None:
            self.default_port = port

        if game_or_factory is None:
            game_or_factory = self.game_factory
        if game_or_factory is not None:
            self.game = game_or_factory() if callable(game_or_factory) \
                else game_or_factory
        self.writers = []

    async def handle_connection(self, reader, writer):
        writers = self.writers
        writers.append(writer)
        index = len(writers)

        print(f"[SERVER#{index}] +Connected.")
        unparsed_bytes = b""
        # self.game.on_connect(index)
        while True:
            # Receive request
            print(f"[SERVER#{index}] (Receiving from client...)")
            try:
                request_bytes = await reader.read(1024)
            except ConnectionError as e:
                print(f"[SERVER#{index}] Error while waiting: {e}")
                break
            if reader.at_eof():
                print(f"[SERVER#{index}] EOF. Connection closed")
                break
            request_bytes = unparsed_bytes + request_bytes

            print(f"[SERVER#{index}] >> Received: {repr(request_bytes)}")

            # Make response
            response_bytes, to_all_bytes, unparsed_bytes = \
                self.game.process_bytes(index, request_bytes)

            # Send response
            print(f"[SERVER#{index}] << Send: {repr(response_bytes)} as response and commands: "
                  f"{repr(to_all_bytes)} to all {len(writers)} connections")
            if response_bytes:
                # Send partially to test client
                mid = int(len(response_bytes) / 2)
                print(f" (send: {response_bytes[:mid]})")
                writer.write(response_bytes[:mid])
                await writer.drain()
                # await asyncio.sleep(.1)  # to test client's buffering
                print(f" (send: {response_bytes[mid:]})")
                writer.write(response_bytes[mid:])
                # writer.write(response_bytes)
                # await writer.drain()
            if to_all_bytes:
                mid = int(len(to_all_bytes) / 2)
                mid2 = int(mid / 2)
                to_all_bytes1 = to_all_bytes[:mid2]
                to_all_bytes2 = to_all_bytes[mid2:mid]
                to_all_bytes3 = to_all_bytes[mid:]
                print(f" (send: {to_all_bytes1})")
                print(f" (send: {to_all_bytes2})")
                print(f" (send: {to_all_bytes3})")
                for w in writers:
                    w.write(to_all_bytes1)
                    await w.drain()
                    # await asyncio.sleep(.1)  # to test client's buffering
                    w.write(to_all_bytes2)
                    await w.drain()
                    # await asyncio.sleep(.1)  # to test client's buffering
                    w.write(to_all_bytes3)
                    # w.write(to_all_bytes)
                    # await w.drain()

        print(f"[SERVER#{index}] -Connection close")
        writers.remove(writer)
        writer.close()
        # self.game.on_disconnect(index)
        try:
            await writer.wait_closed()
        except ConnectionAbortedError as e:
            pass

    async def start(self, host=None, port=None):
        if not host:
            host = self.default_host
        if not port:
            port = self.default_port
        print(f"Start server {host}:{port}")
        await asyncio.start_server(self.handle_connection, host, port)
        while True:
            await asyncio.sleep(1)

    def run(self, host=None, port=None):
        print(f"Run server {host}:{port}")
        asyncio.run(self.start(host, port))
