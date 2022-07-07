"""
Simple blocking socket server.

Changes:
- add endless loop to accept multiple connections, but still only one at a time;
- add try-except for recv() and sendall().
"""

import socket


HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((HOST, PORT))
        serv_sock.listen(1)
        print("Server started")
        # Accepting multiple connections, but only one at a time
        while True:  # New
            print("Waiting for connection...")
            sock, addr = serv_sock.accept()
            with sock:
                print("Connected by", addr)
                while True:
                    # Receive
                    try:  # New
                        data = sock.recv(1024)
                    except ConnectionError:
                        print(f"Client suddenly closed while receiving")
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
                    try:  # New
                        # Uncomment to test exception:
                        # 1) Send data from client and close it
                        # 2) Go to server process and press Enter
                        # 3) Trying to send data to closed client, which cause exception
                        # input("(press enter to send...)")
                        sock.sendall(data)
                    except ConnectionError:
                        print(f"Client suddenly closed, cannot send")
                        break
                print("Disconnected by", addr)
