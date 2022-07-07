import asyncio
import json
import os
import re

last_index = 0
writers = []
storage = {}

# Extract handle_bytes() from handle_connection()
print("socket v2")


def escape(string):
    return re.sub(r"[^A-Za-z]+", "", string)


async def handle_connection(reader, writer):
    global last_index
    global writers
    writers.append(writer)
    last_index += 1
    i = last_index

    print(f"[SERVER#{i}] +Connected.")
    unparsed_bytes = b""
    while True:
        # Receive request
        print(f"[SERVER#{i}] (Receiving from client...)")
        try:
            request_bytes = await reader.read(1024)
        except ConnectionError:
            break
        if reader.at_eof():  # if not request_bytes:  # Same
            print(f"[SERVER#{i}] EOF. Connection closed")
            break

        request_bytes = unparsed_bytes + request_bytes
        request_bytes_list = request_bytes.split(b"\x00")
        unparsed_bytes = request_bytes_list.pop()

        for request_bytes in request_bytes_list:
            if not request_bytes:
                continue
            print(f"[SERVER#{i}] >> Received: {repr(request_bytes)}")

            # Handle
            to_self_bytes, to_all_bytes = handle_bytes(i, request_bytes)

            # Send
            print(f"[SERVER#{i}] << Send: {repr(to_self_bytes)} as self_response and commands: "
                  f"{repr(to_all_bytes)} to all {len(writers)} connections")
            if to_self_bytes:
                try:
                    writer.write(to_self_bytes)
                    await writer.drain()
                except ConnectionError:
                    pass  # Yet must send to others
            if to_all_bytes:
                for w in writers:
                    try:
                        w.write(to_all_bytes)
                        await w.drain()
                    except ConnectionError:
                        continue

    print(f"[SERVER#{i}] -Connection close")
    writers.remove(writer)
    writer.close()
    try:
        await writer.wait_closed()
    except ConnectionError:
        pass


def handle_bytes(i, request_bytes):
    request = request_bytes.decode("utf8")

    # Make response
    if request == "<policy-file-request/>":
        self_response = "<cross-domain-policy>" \
                        '<allow-access-from domain="*" to-ports="*"/>' \
                        "</cross-domain-policy>"
        all_response = None
    else:
        try:
            command = json.loads(request)
            to_self_command, to_rest_command = handle_command(command)
        except Exception as e:
            print(f"[SERVER#{i}] Error while parsing or processing: {request} {e}")
            to_self_command, to_rest_command = {"error": str(e)}, None
        self_response = json.dumps(to_self_command) if to_self_command else None
        all_response = json.dumps(to_rest_command) if to_rest_command else None

    to_self_bytes = self_response.encode("utf8") + b"\x00" if self_response else None
    to_all_bytes = all_response.encode("utf8") + b"\x00" if all_response else None
    return to_self_bytes, to_all_bytes


def handle_command(command):
    key = escape(command.get("key"))
    filename = "../data/save_" + key
    dirname = os.path.dirname(filename)
    if not os.path.exists(dirname):
        os.makedirs(dirname)
    code = command.get("code")
    if code == "save" or code == "set":
        # Save
        state = command.get("state")
        with open(filename, "w") as f:
            json.dump(state, f)
            f.flush()
        print("save", state)
        return {"success": True, **command}, None
    elif code == "load" or code == "get":
        # Load
        if not os.path.exists(filename):
            return {"success": False, **command}, None
        with open(filename, "r") as f:
            state = json.load(f)
        print("load", state)
        return {"success": True, **command, "state": state}, None
    elif code == "update":
        # Update
        index = command.get("index")
        value = command.get("value")
        if not isinstance(index, int) or not isinstance(value, int):
            return {"success": False, **command}, None
        if not os.path.exists(filename):
            state = []
        else:
            with open(filename, "r") as f:
                state = json.load(f)
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        with open(filename, "w") as f:
            json.dump(state, f)
            f.flush()
        print("update", state)
        return None, {"success": True, **command}
    return None, None


async def main(host, port):
    print(f"Start server: {host}:{port}")
    server = await asyncio.start_server(handle_connection, host, port)
    async with server:
        await server.serve_forever()


HOST, PORT = "", 5554
if __name__ == "__main__":
    asyncio.run(main(HOST, PORT))
