"""
Low-level asyncio socket server using async-await syntax (Python 3.5+).

(Using Syntactic sugar: @coroutine -> async, yield from -> await)
https://docs.python.org/3/library/asyncio-eventloop.html#working-with-socket-objects-directly
"""

import asyncio
import socket


@ asyncio.coroutine
def handle_connection(sock, addr):
    loop = asyncio.get_event_loop()
    print("Connected by", addr)
    while True:
        # Receive
        try:
            data = await loop.sock_recv(sock, 1024)
        except ConnectionError:
            print(f"Client suddenly closed while receiving from {addr}")
            break
        print(f"Received: {data} from: {addr}")
        if not data:
            break
        # Process
        if data == b"close":
            break
        data = data.upper()
        # Send
        print(f"Send: {data} to: {addr}")
        try:
            await loop.sock_sendall(sock, data)
        except ConnectionError:
            print(f"Client suddenly closed, cannot send to {addr}")
            break
    print("Disconnected by", addr)
    sock.close()


async def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((host, port))
        serv_sock.listen(1)
        serv_sock.setblocking(False)
        print("Server started")

        loop = asyncio.get_event_loop()
        while True:
            print("Waiting for connection...")
            sock, addr = await loop.sock_accept(serv_sock)
            loop.create_task(handle_connection(sock, addr))


HOST = "localhost"  # The remote host
PORT = 50007  # The same port as used by the server

if __name__ == "__main__":
    asyncio.run(main(HOST, PORT))
