"""
Socket server using Selector made as callback system.
"""

import selectors
import socket

from v0 import server10


def on_connect(sock, addr):
    print("Connected by", addr)


def on_disconnect(sock, addr):
    print("Disconnected by", addr)


def run_server(host, port, on_connect, on_read, on_disconnect):
    def on_accept_ready(sel, serv_sock, mask):
        sock, addr = serv_sock.accept()  # Should be ready
        # sock.setblocking(False)
        sel.register(sock, selectors.EVENT_READ, on_read_ready)
        if on_connect:
            on_connect(sock, addr)

    def on_read_ready(sel, sock, mask):
        addr = sock.getpeername()
        if not on_read or not on_read(sock, addr):
            if on_disconnect:
                on_disconnect(sock, addr)
            sel.unregister(sock)
            sock.close()

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((host, port))
        serv_sock.listen(1)
        # sock.setblocking(False)
        sel = selectors.DefaultSelector()
        sel.register(serv_sock, selectors.EVENT_READ, on_accept_ready)
        while True:
            print("Waiting for connections or data...")
            events = sel.select()
            for key, mask in events:
                callback = key.data
                callback(sel, key.fileobj, mask)


HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    run_server(HOST, PORT, on_connect, server10.handle, on_disconnect)
