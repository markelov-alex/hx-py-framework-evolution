import asyncio
import json
import traceback

writers = []
storage = {}


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
            request = request_bytes.decode('utf8')

            print(f"[SERVER#{i}] >> Received: {repr(request)}")

            # Make response
            if request == "<policy-file-request/>":
                response = "<cross-domain-policy>" \
                           '<allow-access-from domain="*" to-ports="*"/>' \
                           "</cross-domain-policy>"
                to_all = None
            else:
                try:
                    request_data = json.loads(request)
                    response_data, to_all_data = process_command(request_data)
                except Exception as e:
                    print(f"[SERVER#{i}] Error while parsing or processing: {traceback.format_exc()}")
                    response_data, to_all_data = {"error": str(e)}, None
                response = json.dumps(response_data) if response_data else None
                to_all = json.dumps(to_all_data) if to_all_data else None

            # Send response
            print(f"[SERVER#{i}] << Send: {repr(response)} as response and commands: "
                  f"{repr(to_all)} to all {len(writers)} connections")
            if response:
                response_bytes = response.encode('utf8') + b"\x00"
                writer.write(response_bytes)
                # await writer.drain()
            if to_all:
                to_all_bytes = to_all.encode('utf8') + b"\x00"
                for w in writers:
                    w.write(to_all_bytes)
                    # await w.drain()

    print(f"[SERVER#{i}] -Connection close")
    writers.remove(writer)
    writer.close()
    try:
        await writer.wait_closed()
    except ConnectionAbortedError as e:
        pass


def process_command(data):
    if not data:
        return data, []
    global storage
    commands = data if isinstance(data, list) else[data]
    response_commands = []
    commands_to_all = []
    for command in commands:
        code = command.get("code")
        if code == "get":
            name = command.get("name")
            response_commands.append({
                "code": "set",
                "name": name,
                "data": storage.get(name)
            })
        elif code == "update":
            name = command.get("name")
            data = command.get("data")
            # (Get or create empty)
            cur_data = storage[name] = storage.get(name, [])
            # (Update)
            update(cur_data, data)
            # print(f"Storage changed: {storage}")
            # (Send command unchanged to all connections)
            commands_to_all.append(command)
    return response_commands, commands_to_all


def update(target, source):
    for k, v in source.items():
        if k.isdigit():
            k = int(k)
            add_count = k - len(target) + 1
            if add_count > 0:
                target.extend([-1] * add_count)
            if isinstance(v, dict):
                if target[k] == -1:
                    target[k] = []
                update(target[k], v)
            else:
                target[k] = v


async def main():
    await asyncio.start_server(handle_connection, "127.0.0.1", 5555)
    while True:
        await asyncio.sleep(1)


if __name__ == "__main__":
    asyncio.run(main())
