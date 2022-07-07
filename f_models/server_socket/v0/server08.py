"""
Forking blocking socket server using standard high-level API.

https://docs.python.org/3/library/socketserver.html#asynchronous-mixins
"""

import os
import socketserver

from v0 import server06

HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if not hasattr(os, "fork"):
    print("Forking is not available on your system!")
    exit(1)

if __name__ == "__main__":
    with socketserver.ForkingTCPServer(
            (HOST, PORT), server06.ConnectionHandler) as server:
        # Activate the server; this will keep running until you
        # interrupt the program with Ctrl-C
        print("Server started")
        server.serve_forever()
