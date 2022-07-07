from v6.server import Server
from v9.custom import CustomGame, CustomMultiParser

# todo make separate server task for crossdomain xml (inside Server)
if __name__ == "__main__":
    server = Server("localhost", 5555, CustomGame(CustomMultiParser))
    server.run()
