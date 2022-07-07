from v6.custom import CustomGame
from v6.custom import CustomMultiAutoParser
from v6.server import Server

# todo make separate server task for crossdomain xml (inside Server)
if __name__ == "__main__":
    server = Server("localhost", 5555, CustomGame(CustomMultiAutoParser))
    server.run()
