from v0.custom import CustomGame
from v0.custom import CustomMultiParser
from v0.server import Server

# v0 - is always the last version of the previous project
# todo make separate server task for crossdomain xml (inside Server)
if __name__ == "__main__":
    server = Server("localhost", 5555, CustomGame(CustomMultiParser))
    server.run()
