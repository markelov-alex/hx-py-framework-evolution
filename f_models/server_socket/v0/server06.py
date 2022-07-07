"""
From low-level to high-level API.

Blocking socket server using standard high-level API.

https://docs.python.org/3/library/socketserver.html#socketserver-tcpserver-example
"""

import socketserver


class ConnectionHandler(socketserver.BaseRequestHandler):
    def setup(self):
        print("Connected by", self.client_address)

    def handle(self):
        while True:
            # Receive
            try:
                data = self.request.recv(1024)
            except ConnectionError:
                print(f"Client suddenly closed while receiving")
                break
            print(f"Received: {data} from: {self.client_address}")
            if not data:
                break
            # Process
            if data == b"close":
                break
            data = data.upper()
            # Send
            print(f"Send: {data} to: {self.client_address}")
            try:
                self.request.sendall(data)
            except ConnectionError:
                print(f"Client suddenly closed, cannot send")
                break
        # print("Disconnected by", self.client_address)

    def finish(self):
        print("Disconnected by", self.client_address)


HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    with socketserver.TCPServer((HOST, PORT), ConnectionHandler) as server:
        # Activate the server; this will keep running until you
        # interrupt the program with Ctrl-C
        print("Server started")
        server.serve_forever()
