"""
Socket server using Selector and callbacks.

https://docs.python.org/3/library/selectors.html#examples
"""

import selectors
import socket

from v0 import server10


def on_accept_ready(sel, serv_sock, mask):
    sock, addr = serv_sock.accept()  # Should be ready
    print("Connected by", addr)
    # sock.setblocking(False)
    sel.register(sock, selectors.EVENT_READ, on_read_ready)


def on_read_ready(sel, sock, mask):
    addr = sock.getpeername()
    if not server10.handle(sock, addr):
        sel.unregister(sock)
        sock.close()


HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((HOST, PORT))
        serv_sock.listen(1)
        # serv_sock.setblocking(False)
        print("Server started")

        sel = selectors.DefaultSelector()
        sel.register(serv_sock, selectors.EVENT_READ, on_accept_ready)
        while True:
            print("Waiting for connections or data...")
            events = sel.select()
            for key, mask in events:
                callback = key.data
                callback(sel, key.fileobj, mask)
