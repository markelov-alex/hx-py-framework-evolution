import functools

from v4.custom import CustomConverter, CustomGame as PrevCustomGame
from v5.game import Game
from v5.parser import BinaryParser
from v5.parser import JSONParserExt


class CustomJSONParser(JSONParserExt):
    converter = CustomConverter()


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
    # Note: Use big numbers (> 128) to test unsigned bytes encoded properly
    code_by_str = {
        "big": 1,
        "little": 2,
        "get": 3,
        "set": 4,
        "update": 250,
        "dresserState": -10,
        "pictureStates": 120,
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


class CustomGame(Game):
    parser = CustomJSONParser()

    def __init__(self, parser_or_factory=None, commands_handler=None) -> None:
        if not commands_handler:
            commands_handler = functools.partial(PrevCustomGame.handle_commands, self)
        super().__init__(parser_or_factory, commands_handler)
        self.storage = {}


# Enable doc tests when debugging current module
if __name__ == "__main__":
    import doctest
    doctest.testmod()
