import asyncio

from v4.custom import CustomGame

# Business logic
game = CustomGame()
# State
writers = []


async def handle_connection(reader, writer):
    global writers
    writers.append(writer)
    i = len(writers)

    print(f"[SERVER#{i}] +Connected.")
    while True:
        # Receive request
        print(f"[SERVER#{i}] (Receiving from client...)")
        try:
            request_bytes = await reader.read(1024)
        except ConnectionAbortedError as e:
            print(f"[SERVER#{i}] Error while waiting: {e}")
            break
        if reader.at_eof():
            print(f"[SERVER#{i}] EOF. Connection closed")
            break

        request_bytes_list = request_bytes.split(b"\x00")
        for request_bytes in request_bytes_list:
            if not request_bytes:
                continue

            print(f"[SERVER#{i}] >> Received: {repr(request_bytes)}")

            # Make response
            response_bytes, to_all_bytes = game.process_bytes(request_bytes)

            # Send response
            print(f"[SERVER#{i}] << Send: {repr(response_bytes)} as response and commands: "
                  f"{repr(to_all_bytes)} to all {len(writers)} connections")
            if response_bytes:
                writer.write(response_bytes + b"\x00")
                # await writer.drain()
            if to_all_bytes:
                for w in writers:
                    w.write(to_all_bytes + b"\x00")
                    # await w.drain()

    print(f"[SERVER#{i}] -Connection close")
    writers.remove(writer)
    writer.close()
    try:
        await writer.wait_closed()
    except ConnectionAbortedError as e:
        pass


async def main():
    await asyncio.start_server(handle_connection, "127.0.0.1", 5555)
    while True:
        await asyncio.sleep(1)


if __name__ == "__main__":
    asyncio.run(main())
