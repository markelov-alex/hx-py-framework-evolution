from v4.custom import update
from v5.custom import CustomJSONParser
from v5.parser import JSONParser
from v6.custom import CustomBinaryParser
from v6.game import Game
from v9.parser import MultiParser


class CustomMultiParser(MultiParser):
    # Settings
    default_version = b"v.1.0.0"
    parser_or_factory_by_version = {
       b"v.1.0.0": JSONParser,
       b"v.2.0.0": CustomJSONParser,
       b"v.3.0.0": CustomBinaryParser,
    }


class CustomGame(Game):
    # State
    counter = 0

    def __init__(self, parser_factory=None, commands_handler=None) -> None:
        super().__init__(parser_factory, commands_handler)
        self.storage = {}

        # Get versions
        temp_parser = self.parser_factory()
        self.versions = list(temp_parser.parser_or_factory_by_version) \
            if hasattr(temp_parser, "parser_or_factory_by_version") else []

    def handle_commands(self, index, commands):
        if not commands:
            return commands, []
        response_commands = []
        commands_to_all = []
        for command in commands:
            if isinstance(command, bytes) and command in self.versions:
                # Send version back
                response_commands.append(command)
                continue
            if not isinstance(command, dict):
                continue
            code = command.get("code")
            if code == "get":
                name = command.get("name")
                response_commands.append({
                    "code": "set",
                    "name": name,
                    "data": self.storage.get(name)
                })
            elif code == "update":
                name = command.get("name")
                data = command.get("data")
                # (Get or create empty)
                cur_data = self.storage[name] = self.storage.get(name, [])
                # (Update)
                update(cur_data, data)
                # print(f"Storage changed: {storage}")
                # (Send command unchanged to all connections)
                commands_to_all.append(command)

        # Change version from server side on every N serializations
        if commands_to_all:
            self.counter += 1
            if self.counter > 4:
                self.counter = 0
                parser = self.parser_by_index.get(index)
                if parser and self.versions and parser.version in self.versions:
                    ver_index = self.versions.index(parser.version)
                    ver_index = ver_index + 1 if ver_index + 1 < len(self.versions) else 0
                    new_version = self.versions[ver_index]
                    response_commands.extend(self.versions)  # temp
                    response_commands.append(new_version)
                    print(f"\n\nAuto change of protocol version for: #{index} {parser.version} -> {new_version}")
        return response_commands, commands_to_all
