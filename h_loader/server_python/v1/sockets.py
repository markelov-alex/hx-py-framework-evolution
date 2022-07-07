from v1.custom import CustomGame
from v1.custom import CustomMultiParser
from v0.server import Server

# todo make separate server task for crossdomain xml (inside Server)
# Changes:
#  - add goto command separating games to rooms,
#  - that also allow us to test how our system deals with new protocol versions.
if __name__ == "__main__":
    server = Server("localhost", 5555, CustomGame(CustomMultiParser))
    server.run()
