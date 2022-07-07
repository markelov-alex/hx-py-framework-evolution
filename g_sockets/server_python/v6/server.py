from v5.server import Server as PrevServer


# Changes:
#  - send responses by index.
class Server(PrevServer):
    max_index = 0

    def __init__(self, host=None, port=None, game_or_factory=None) -> None:
        super().__init__(host, port, game_or_factory)
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
