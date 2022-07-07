"""
Socket server using Selector and generators.

Refactored making more familiar with asyncio.

(On the way to async-await.)

https://realpython.com/introduction-to-python-generators/
https://docs.python.org/3/library/selectors.html#examples
"""

import selectors
import socket
from inspect import isgenerator


# Loop

def run(main):
    loop = get_event_loop()
    loop.run_forever(main)


loop = None


def get_event_loop():
    global loop
    if not loop:
        loop = SelectorLoop()
    return loop


class SelectorLoop:

    def __init__(self) -> None:
        super().__init__()
        self._selector = selectors.DefaultSelector()
        self._current_gen = None  # Currently executing generator
        self._ready = []

    def run_forever(self, main_gen):
        assert isgenerator(main_gen)
        self.create_task(main_gen)
        while True:
            self._run_once()

    def create_task(self, gen):
        assert isgenerator(gen)
        print(f"(Create task {gen}...)")
        self._ready.append(gen)

    def wait_for(self, fileobj):
        self._selector.register(fileobj, selectors.EVENT_READ, self._current_gen)

    def _run_once(self):
        # Ready tasks
        self._process_tasks(self._ready)
        # Ready IO
        print("Waiting for connections or data...")
        events = self._selector.select()
        self._process_events(events)

    def _process_tasks(self, tasks):
        while tasks:
            print(f"(Run task {tasks[0]}...)")
            self._run(tasks.pop(0))

    def _process_events(self, events):
        for key, mask in events:
            self._selector.unregister(key.fileobj)
            gen = key.data
            self._run(gen)

    def _run(self, gen):
        assert gen
        self._current_gen = gen
        try:
            next(gen)
        except StopIteration:
            # Generator returns, not yields (on disconnect)
            pass

    def sock_accept(self, serv_sock):
        sock, addr = serv_sock.accept()  # Should be ready
        # sock.setblocking(False)
        return sock, addr

    def sock_recv(self, sock, nbytes):
        return sock.recv(nbytes)

    def sock_sendall(self, sock, data):
        sock.send(data)


# Server

def main(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((host, port))
        serv_sock.listen(1)
        # serv_sock.setblocking(False)
        print("Server started")

        loop = get_event_loop()
        while True:
            yield loop.wait_for(serv_sock)
            sock, addr = loop.sock_accept(serv_sock)
            print("Connected by", addr)
            loop.create_task(handle_connection(sock, addr))


def handle_connection(sock, addr):
    while True:
        # Receive
        try:
            yield loop.wait_for(sock)
            data = loop.sock_recv(sock, 1024)  # Should be ready
        except ConnectionError:
            print(f"Client suddenly closed while receiving")
            break
        print(f"Received {data} from: {addr}")
        if not data:
            break
        # Process
        if data == b"close":
            break
        data = data.upper()
        # Send
        print(f"Send: {data} to: {addr}")
        try:
            loop.sock_sendall(sock, data)  # Hope it won't block
        except ConnectionError:
            print(f"Client suddenly closed, cannot send")
            break
    sock.close()
    print("Disconnected by", addr)


HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    run(main(HOST, PORT))
