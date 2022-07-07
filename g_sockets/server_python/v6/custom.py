import functools

from v4.custom import CustomGame as PrevCustomGame
from v5.custom import CustomJSONParser, CustomBinaryParser as CustomBinaryParserOld
from v5.parser import JSONParser, BinaryParser
from v6.game import Game
from v6.parser import MultiParser, AutoMultiParser


# As changes in CustomBinaryParserOld are much bigger than in
# v6 BinaryParser, it's much simplier to extend CustomBinaryParserOld
# and copy code from v6 BinaryParser.
class CustomBinaryParser(CustomBinaryParserOld):

    def serialize(self, data):
        # Serialize (list of dicts or dict -> bytes)
        result = super().serialize(data)
        # Add length field before bytes (bytes -> bytes)
        return BinaryParser.serialize_bytes_list([result])

    def parse(self, data_bytes):
        # Remove length field (bytes -> list of bytes)
        bytes_list, unparsed_bytes = BinaryParser.parse_bytes_list(data_bytes)
        # Parse (list of bytes -> list of commands)
        result = []
        for byteorder, b in bytes_list:
            result.extend(super().parse(b)[0])
        return result, unparsed_bytes


class CustomMultiParser(MultiParser):
    # Settings
    default_version = b"v.1.0.0"
    parser_or_factory_by_version = {
       b"v.1.0.0": JSONParser,
       b"v.2.0.0": CustomJSONParser,
       b"v.3.0.0": CustomBinaryParser,
    }


class CustomMultiAutoParser(AutoMultiParser):
    # Settings
    default_version = b"v.1.0.0"
    # default_version = b"v.3.0.0"  # temp
    parser_or_factory_by_version = {
        b"v.1.0.0": JSONParser,
        b"v.2.0.0": CustomJSONParser,
        b"v.3.0.0": CustomBinaryParser,
    }


class CustomGame(Game):
    # State
    counter = 0

    def __init__(self, parser_factory=None, commands_handler=None) -> None:
        if not commands_handler:
            commands_handler = functools.partial(PrevCustomGame.handle_commands, self)
        super().__init__(parser_factory, commands_handler)
        self.storage = {}

        # Get versions
        temp_parser = self.parser_factory()
        self.versions = list(temp_parser.parser_or_factory_by_version) \
            if hasattr(temp_parser, "parser_or_factory_by_version") else []

    def handle_commands(self, index, commands):
        response_commands, commands_to_all = \
            super().handle_commands(index, commands)

        # Change version from server side on every N serializations
        if commands_to_all:
            self.counter += 1
            if self.counter > 2:
                self.counter = 0
                parser = self.parser_by_index.get(index)
                if parser and self.versions and parser.version in self.versions:
                    ver_index = self.versions.index(parser.version)
                    ver_index = ver_index + 1 if ver_index + 1 < len(self.versions) else 0
                    new_version = self.versions[ver_index]
                    response_commands.append(new_version)
                    print(f"\n\nAuto change of protocol version for: #{index} {parser.version} -> {new_version}")
        return response_commands, commands_to_all
