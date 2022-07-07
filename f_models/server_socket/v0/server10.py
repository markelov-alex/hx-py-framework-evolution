"""
Socket server using select.select().
(Low-level API)

Blocking doesn't matter as select() always return ready sockets.

http://pymotw.com/2/select/
https://docs.python.org/3/howto/sockets.html#non-blocking-sockets
"""

import select
import socket


def handle(sock, addr):
    # Receive
    try:
        data = sock.recv(1024)  # Should be ready
    except ConnectionError:
        print(f"Client suddenly closed while receiving")
        return False
    print(f"Received {data} from: {addr}")
    if not data:
        print("Disconnected by", addr)
        return False
    # Process
    if data == b"close":
        return False
    data = data.upper()
    # Send
    print(f"Send: {data} to: {addr}")
    try:
        sock.send(data)  # Hope it won't block
    except ConnectionError:
        print(f"Client suddenly closed, cannot send")
        return False
    return True


HOST = ""  # Symbolic name meaning all available interfaces
PORT = 50007  # Arbitrary non-privileged port

if __name__ == "__main__":
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as serv_sock:
        serv_sock.bind((HOST, PORT))
        serv_sock.listen(1)
        # serv_sock.setblocking(False)
        print("Server started")

        inputs = [serv_sock]
        outputs = []
        while True:
            print("Waiting for connections or data...")
            # Note: We don't check writeables, because, "actually, any
            # reasonably healthy socket will return as writable -
            # it just means outbound network buffer space is available."
            # (https://docs.python.org/3/howto/sockets.html#non-blocking-sockets)
            readable, writeable, exceptional = select.select(inputs, outputs, inputs)

            for sock in readable:
                if sock == serv_sock:
                    sock, addr = serv_sock.accept()  # Should be ready
                    print("Connected by", addr)
                    # sock.setblocking(False)
                    inputs.append(sock)
                else:
                    addr = sock.getpeername()
                    if not handle(sock, addr):
                        # Disconnected
                        inputs.remove(sock)
                        if sock in outputs:
                            outputs.remove(sock)
                        sock.close()
            for sock in exceptional:
                # Disconnected
                inputs.remove(sock)
                if sock in outputs:
                    outputs.remove(sock)
                sock.close()
