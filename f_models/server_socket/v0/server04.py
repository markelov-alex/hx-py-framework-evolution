"""
Simple forking blocking socket server.

Changes:
- use forking to avoid blocking (naively)
"""

import os
import socket

from v0 import server03

HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if not hasattr(os, "fork"):
    print("Forking is not available on your system!")
    exit(1)

if __name__ == "__main__":
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((HOST, PORT))
        serv_sock.listen(1)
        print("Server started")
        while True:
            print("Waiting for connection...")
            sock, addr = serv_sock.accept()
            pid = os.fork()
            if pid:
                # Continue parent process
                pass
            else:
                # Start child process
                server03.handle_connection(sock, addr)
                exit()
