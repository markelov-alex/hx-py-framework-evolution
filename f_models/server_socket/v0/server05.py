"""
Simple multiprocessing blocking socket server.

Changes:
- use processes to avoid blocking (naively).
"""

import multiprocessing
import socket

from v0 import server03

HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((HOST, PORT))
        serv_sock.listen(1)
        print("Server started")
        while True:
            print("Waiting for connection...")
            sock, addr = serv_sock.accept()
            p = multiprocessing.Process(target=server03.handle_connection,
                                        args=(sock, addr))  # New
            p.start()
