import asyncio


class Server:
    # Settings
    default_host = None
    default_port = None
    game_factory = None
    # State
    game = None
    max_index = 0

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
        # self.writers = []
        self.writer_by_index = {}

    async def handle_connection(self, reader, writer):
        self.max_index += 1
        index = self.max_index
        # self.writers.append(writer)
        self.writer_by_index[index] = writer

        print(f"[SERVER#{index}] +Connected.")
        unparsed_bytes = b""
        self.game.on_connect(index)
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
            result, unparsed_bytes = self.game.process_bytes(index, request_bytes)

            if not result:
                print(f"[SERVER#{index}] No response. Skip.")
                continue

            # Send response
            print(f"[SERVER#{index}] << Send responses: {repr(result)}")
            for i, response_bytes in result:
                if response_bytes:
                    w = self.writer_by_index.get(i)
                    # Send partially to test client
                    mid = int(len(response_bytes) / 2)
                    print(f"[SERVER#{index}]  (to: {i} send: {response_bytes[:mid]})")
                    w.write(response_bytes[:mid])
                    await w.drain()
                    # await asyncio.sleep(.1)  # to test client's buffering
                    print(f"[SERVER#{index}]  (to: {i} send: {response_bytes[mid:]})")
                    w.write(response_bytes[mid:])
                    # w.write(response_bytes)
                    # await w.drain()

        print(f"[SERVER#{index}] -Connection close")
        # self.writers.remove(writer)
        del self.writer_by_index[index]
        writer.close()
        self.game.on_disconnect(index)
        try:
            await writer.wait_closed()
        except ConnectionError as e:
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
