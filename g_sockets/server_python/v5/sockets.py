from v5.custom import CustomGame
from v5.custom import CustomBinaryParser
from v5.server import Server

if __name__ == "__main__":
    server = Server("localhost", 5555, CustomGame(CustomBinaryParser))
    server.run()
