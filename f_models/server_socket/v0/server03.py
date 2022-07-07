"""
Simple threaded blocking socket server.

Changes:
- use threads to avoid blocking (naively).
"""

import socket
import threading


def handle_connection(sock, addr):  # New
    with sock:
        print("Connected by", addr)
        while True:
            # Receive
            try:
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
            try:
                sock.sendall(data)
            except ConnectionError:
                print(f"Client suddenly closed, cannot send")
                break
        print("Disconnected by", addr)


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
            t = threading.Thread(target=handle_connection, args=(sock, addr))  # New
            t.start()
