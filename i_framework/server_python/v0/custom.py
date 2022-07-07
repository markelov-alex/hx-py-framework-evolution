from v0.game import Game
from v0.parser import BinaryParser
from v0.parser import DataConverter
from v0.parser import JSONParser
from v0.parser import JSONParserExt
from v0.parser import MultiParser


class CustomConverter(DataConverter):
    # Settings
    code_index = 0
    code_field = "code"

    def __init__(self) -> None:
        super().__init__()
        self.fields_by_code = {
            "set": ["code", "name", "data"],
            "update": ["code", "name", "data"],
            "*": ["code", "name", "data"],
            # (Not necessary as "*" has same format)
            "goto": ["code", "name", "data"],
        }


class CustomJSONParser(JSONParserExt):
    converter = CustomConverter()


# Changes:
#  - use init() to set up codes.
class CustomBinaryParser(BinaryParser):
    """
    >>> p = CustomBinaryParser()
    >>> p.parse(p.serialize({'command': 'get', 'name': 'dresserState', 'data': [2, 0, 1]}))
    ([{'command': 'get', 'name': 'dresserState', 'data': [2, 0, 1]}], b'')
    >>> p.parse(p.serialize({'command': 'update', 'name': 'dresserState', 'data': {'0': 1, '2': 0}}))
    ([{'command': 'update', 'name': 'dresserState', 'data': {'0': 1, '2': 0}}], b'')
    >>> p.parse(p.serialize({'command': 'set', 'name': 'pictureStates', 'data': [[1234567, 234567, -1, 34567], [0, 1234567]]}))
    ([{'command': 'set', 'name': 'pictureStates', 'data': [[1234567, 234567, -1, 34567], [0, 1234567]]}], b'')
    >>> p.parse(p.serialize({'command': 'update', 'name': 'pictureStates', 'data': {'0': {'1': 5, '2': 6}, '3': {'5': 1234567}}}))
    ([{'command': 'update', 'name': 'pictureStates', 'data': {'0': {'1': 5, '2': 6}, '3': {'5': 1234567}}}], b'')
    """

    # Settings

    def init(self):
        super().init()
        # Note: Use big numbers (> 128) to test unsigned bytes encoded properly
        self.code_by_str = {
            "big": 1,
            "little": 2,
            "get": 3,
            "set": 4,
            "update": 250,
            "dresserState": -10,
            "pictureStates": 120,

            "goto": 5,
            "lobby": 20,
            "dresser1": 30,
            "dresser2": 31,
            "dresser3": 32,
            "coloring1": 40,
            "coloring2": 41,
            "coloring3": 42,
        }

    def _serialize_item(self, item, byteorder):
        assert isinstance(item, dict)
        # Command
        command = item.get("code")
        command_code = self.code_by_str.get(command, 0)
        command_bytes = int.to_bytes(command_code, 1, byteorder)
        name = item.get("name")
        name_code = self.code_by_str.get(name, 0)
        name_bytes = int.to_bytes(name_code, 1, byteorder, signed=True)
        data = item.get("data")
        data_bytes = self._serialize_data_field(command, name, data, byteorder)
        # Result
        return command_bytes + name_bytes + data_bytes

    def _parse_item(self, item_bytes, byteorder):
        # Command
        command_code = int.from_bytes(item_bytes[:1], byteorder)
        command = self.str_by_code.get(command_code)
        name_code = int.from_bytes(item_bytes[1:2], byteorder, signed=True)
        name = self.str_by_code.get(name_code)
        # ("data" field occupies all bytes between name and the end of the command)
        data = self._parse_data_field(command, name, item_bytes[2:len(item_bytes)], byteorder)
        # Result
        return {"code": command, "name": name, "data": data}

    def _serialize_data_field(self, command, name, data, byteorder):
        if not data:
            return b""
        if name == "dresserState":
            if isinstance(data, dict):
                # For "update" command
                data = self._dict_to_int_list(data, 1)
            # For "set" and "update" command
            data_bytes = self.serialize_int_list(data, 1, byteorder)
            return data_bytes
        elif name == "pictureStates":
            if isinstance(data, dict):
                # For "update" command
                data_list = self._dict_to_int_list(data, 2)
                data_bytes = self.serialize_int_list(data_list, 4, byteorder, True)
            else:
                # For "set" command
                bytes_list = [self.serialize_int_list(d, 4, byteorder, True) for d in data]
                data_bytes = self.serialize_bytes_list(bytes_list, byteorder)
            return data_bytes
        return b""

    def _parse_data_field(self, command, name, data_bytes, byteorder):
        if not data_bytes:
            return None
        if name == "dresserState":
            result = self.parse_int_list(data_bytes, 1, byteorder)
            if command == "update":
                result = self._int_list_to_dict(result, 1)
            return result
        elif name == "pictureStates":
            if command == "update":
                data_list = self.parse_int_list(data_bytes, 4, byteorder, True)
                result = self._int_list_to_dict(data_list, 2)
            else:
                bytes_list, unparsed_bytes = self.parse_bytes_list(data_bytes, byteorder)
                result = [self.parse_int_list(b, 4, bo, True) for bo, b in bytes_list]
            return result
        return None

    # Utility

    def _dict_to_int_list(self, data, nesting=1, *, item_res=None, result=None):
        """
        >>> CustomBinaryParser()._dict_to_int_list({"0": 5, "2": 6}, 1)
        [0, 5, 2, 6]
        >>> CustomBinaryParser()._dict_to_int_list({"0": {"1": 5, "2": 6}, "3": {"4": 5, "5": 6}}, 2)
        [0, 1, 5, 0, 2, 6, 3, 4, 5, 3, 5, 6]
        """
        result = result if result else []
        for k, v in data.items():
            if nesting > 1:
                cur_item_res = item_res.copy() if item_res else []
                cur_item_res.append(int(k))
                result = self._dict_to_int_list(v, nesting - 1, item_res=cur_item_res, result=result)
            else:
                if item_res:
                    result.extend(item_res)
                result.append(int(k))
                result.append(v)

        return result

    def _int_list_to_dict(self, data, nesting=1):
        """
        >>> CustomBinaryParser()._int_list_to_dict([0, 5, 2, 6], 1)
        {'0': 5, '2': 6}
        >>> CustomBinaryParser()._int_list_to_dict([0, 1, 5, 0, 2, 6, 3, 4, 5, 3, 5, 6], 2)
        {'0': {'1': 5, '2': 6}, '3': {'4': 5, '5': 6}}
        """
        result = {}
        i = 0
        while i < len(data):
            res = result
            for n in range(nesting):
                key = str(data[i])
                i += 1
                if n < nesting - 1:
                    new_res = res.get(key)
                    if new_res is None:
                        res[key] = res = {}
                    else:
                        res = new_res
                else:
                    val = data[i]
                    i += 1
                    res[key] = val

        return result


class CustomBinaryParser2(CustomBinaryParser):
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


class CustomMultiParser(MultiParser):
    # Settings
    default_version = b"v.1.0.0"
    parser_or_factory_by_version = {
        b"v.1.0.0": JSONParser,
        b"v.2.0.1": CustomJSONParser,
        b"v.3.0.1": CustomBinaryParser,
        b"v.3.0.2": CustomBinaryParser2,
    }


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


def update(target, source):
    # target = [[1, 2, 3], [4, 5, 6]]
    # source = {"0": {"1": 7}}
    # will change target: [[1, 7, 3], [4, 5, 6]]
    for k, v in source.items():
        if k.isdigit():
            k = int(k)
            add_count = k - len(target) + 1
            if add_count > 0:
                target.extend([-1] * add_count)
            if isinstance(v, dict):
                if target[k] == -1:
                    target[k] = []
                update(target[k], v)
            else:
                target[k] = v


# Enable doc tests when debugging current module
if __name__ == "__main__":
    import doctest
    doctest.testmod()
