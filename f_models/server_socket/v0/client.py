"""
Simple socket client for testing servers.

https://docs.python.org/3/library/socket.html#example

Run one of the servers and a few of clients.

All servers are functionally identical, so the client is same for them all.
Only an implementation is different.

For more control, don't enable auto-reconnect, but restart the client on
each disconnection.
"""

import socket


HOST = "localhost"  # The remote host
PORT = 50007  # The same port as used by the server
IS_RECONNECT_ENABLED = False


if __name__ == "__main__":
    is_started = False
    while IS_RECONNECT_ENABLED or not is_started:
        is_started = True
        print()
        print("Create client")
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((HOST, PORT))
            print("Client connected")
            while True:
                # Input
                data = input("Type the message to send:")
                if data == "exit":
                    print("Close by client")
                    break
                # Send
                data_bytes = data.encode()
                sock.sendall(data_bytes)
                # Receive
                data_bytes = sock.recv(1024)
                data = data_bytes.decode()
                print("Received:", repr(data))
                if not data:
                    print("Closed by server")
                    break
            sock.close()
            print("Client disconnected")
