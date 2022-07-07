"""
Socket server using Selector.
(High-level API. A wrapper over select(), poll(), ...)

https://livebook.manning.com/book/concurrency-in-python-with-asyncio/chapter-3/v-7/75
"""

import selectors
import socket

from v0 import server10

HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((HOST, PORT))
        serv_sock.listen(1)
        # serv_sock.setblocking(False)
        print("Server started")

        sel = selectors.DefaultSelector()
        sel.register(serv_sock, selectors.EVENT_READ)
        while True:
            print("Waiting for connections or data...")
            events = sel.select()

            for key, mask in events:
                sock = key.fileobj
                if sock == serv_sock:
                    sock, addr = serv_sock.accept()  # Should be ready
                    print("Connected by", addr)
                    # sock.setblocking(False)
                    sel.register(sock, selectors.EVENT_READ)
                else:
                    addr = sock.getpeername()
                    if not server10.handle(sock, addr):
                        # Disconnected
                        sel.unregister(sock)
                        sock.close()
                        continue
