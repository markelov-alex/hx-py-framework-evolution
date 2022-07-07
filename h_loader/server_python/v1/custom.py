from v0.custom import update, CustomConverter as CustomConverter0, \
    CustomBinaryParser as CustomBinaryParser0, \
    CustomMultiParser as CustomMultiParser0
from v0.parser import JSONParserExt
from v1.game import Game


class CustomConverter(CustomConverter0):
    def __init__(self) -> None:
        super().__init__()
        # (Not necessary as "*" has same format)
        self.fields_by_code["goto"] = ["code", "name", "data"]


class CustomJSONParser(JSONParserExt):
    converter = CustomConverter()


class CustomBinaryParser(CustomBinaryParser0):
    def init(self):
        super().init()
        self.code_by_str["goto"] = 5
        self.code_by_str["lobby"] = 20
        self.code_by_str["dresser1"] = 30
        self.code_by_str["dresser2"] = 31
        self.code_by_str["dresser3"] = 32
        self.code_by_str["coloring1"] = 40
        self.code_by_str["coloring2"] = 41
        self.code_by_str["coloring3"] = 42


class CustomBinaryParser2(CustomBinaryParser0):
    def init(self):
        super().init()
        self.code_by_str["goto"] = 55
        self.code_by_str["lobby"] = 60
        self.code_by_str["dresser1"] = 70
        self.code_by_str["dresser2"] = 71
        self.code_by_str["dresser3"] = 72
        self.code_by_str["coloring1"] = 80
        self.code_by_str["coloring2"] = 81
        self.code_by_str["coloring3"] = 82


# class CustomMultiParser(MultiParser):
#     # Settings
#     default_version = b"v.1.0.0"
#     parser_or_factory_by_version = {
#         b"v.1.0.0": JSONParser,
#         # b"v.2.0.0": CustomJSONParser0,
#         b"v.2.0.1": CustomJSONParser,
#         # b"v.3.0.0": CustomBinaryParser0,
#         b"v.3.0.1": CustomBinaryParser,
#         b"v.3.0.2": CustomBinaryParser2,
#     }


class CustomMultiParser(CustomMultiParser0):
    def __init__(self) -> None:
        super().__init__()
        self.parser_or_factory_by_version[b"v.2.0.1"] = CustomJSONParser
        self.parser_or_factory_by_version[b"v.3.0.1"] = CustomBinaryParser
        self.parser_or_factory_by_version[b"v.3.0.2"] = CustomBinaryParser2
        if b"v.2.0.0" in self.parser_or_factory_by_version:
            del self.parser_or_factory_by_version[b"v.2.0.0"]
        if b"v.3.0.0" in self.parser_or_factory_by_version:
            del self.parser_or_factory_by_version[b"v.3.0.0"]


# Changes:
#  - refactor the way commands are handled,
#  - add goto command support.
class CustomGame(Game):
    # Settings
    default_room_name = "lobby"
    # State
    counter = 0

    # todo
    # def __init__(self, commands_handler=None, parser_factory=None) -> None:
    def __init__(self, parser_factory=None, commands_handler=None) -> None:
        super().__init__(parser_factory, commands_handler)

        self.room_name_by_index = {}
        self.storage_by_room = {}
        self.storage = None  # current room storage
        self.name_by_room_subname = {
            "dresser": "dresserState",
            "coloring": "pictureStates",
        }

        # Get versions
        temp_parser = self.parser_factory()
        self.versions = list(temp_parser.parser_or_factory_by_version) \
            if hasattr(temp_parser, "parser_or_factory_by_version") else []

    def on_connect(self, index):
        super().on_connect(index)

        # Add to default room (lobby) on connect
        self.room_name_by_index[index] = self.default_room_name
        self.storage = self.storage_by_room.get(self.default_room_name)
        if self.storage is None:
            self.storage = self.storage_by_room[self.default_room_name] = {}
        indexes = self.storage.get("indexes")
        if indexes is None:
            self.storage["indexes"] = indexes = []
        indexes.append(index)

    def on_disconnect(self, index):
        # Remove from room
        room_name = self.room_name_by_index.get(index)
        storage = self.storage_by_room.get(room_name)
        indexes = storage.get("indexes") if storage else None
        if indexes and index in indexes:
            indexes.remove(index)
            del self.room_name_by_index[index]

        super().on_disconnect(index)

    def handle_commands(self, index, commands):
        if not commands:
            return []

        # Provide to each player his individual storage
        room_name = self.room_name_by_index.get(index, self.default_room_name)
        self.storage = self.storage_by_room.get(room_name)
        if self.storage is None:
            self.storage = self.storage_by_room[room_name] = {}
        to_self, to_all = self._handle_commands(index, commands)
        all_indexes = self.storage.get("indexes", [index])
        return [(to_self, [index]), (to_all, all_indexes)]

    def _handle_commands(self, index, commands):
        if not commands:
            return commands, []
        to_self = []
        to_all = []
        for command in commands:
            a, b = self._handle_command(index, command)
            if a:
                to_self.extend(a)
            if b:
                to_all.extend(b)
        return to_self, to_all

    def _handle_command(self, index, command):
        if isinstance(command, bytes) and command in self.versions:
            # Send version back
            return [command], None
        if not isinstance(command, dict):
            print(f"Wrong type of command: {command}! Should be dict or version (bytes).")
            return None, None
        code = command.get("code")
        to_self, to_all = None, None
        if code == "get":
            name = command.get("name")
            to_self = [{
                "code": "set",
                "name": name,
                "data": self.storage.get(name)
            }]
        elif code == "update":
            name = command.get("name")
            data = command.get("data")
            # (Get or create empty)
            cur_data = self.storage[name] = self.storage.get(name, [])
            # (Update)
            update(cur_data, data)
            # print(f"Storage changed: {storage}")
            # (Send command unchanged to all connections)
            to_all = [command]
        elif code == "goto":
            room_name = command.get("name")
            # Remove from previous room
            prev_indexes = self.storage.get("indexes")
            if prev_indexes and index in prev_indexes:
                prev_indexes.remove(index)
            # Add to new room
            self.storage = self.storage_by_room.get(room_name)
            if self.storage is None:
                self.storage = self.storage_by_room[room_name] = {}
            new_indexes = self.storage.get("indexes")
            if new_indexes is None:
                self.storage["indexes"] = new_indexes = []
            if index not in new_indexes:
                new_indexes.append(index)
            self.room_name_by_index[index] = room_name
            # Send back unchanged
            to_self = [command]
            # Refresh current state
            name = None
            for room_subname, n in self.name_by_room_subname.items():
                if room_name.find(room_subname) != -1:
                    name = n
                    break
            to_self.append({
                "code": "set",
                "name": name,
                "data": self.storage.get(name)
            })

        # Change version from server side on every N serializations
        if to_all:
            if not to_self:
                to_self = []
            self.counter += 1
            if self.counter > 4:
                self.counter = 0
                parser = self.parser_by_index.get(index)
                if parser and self.versions and parser.version in self.versions:
                    ver_index = self.versions.index(parser.version)
                    ver_index = ver_index + 1 if ver_index + 1 < len(self.versions) else 0
                    new_version = self.versions[ver_index]
                    to_self.extend(self.versions)  # temp
                    to_self.append(new_version)
                    print(f"\n\nAuto change of protocol version for: #{index} {parser.version} -> {new_version}")
        return to_self, to_all
