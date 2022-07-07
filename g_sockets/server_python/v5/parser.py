import json


class Parser:
    # Settings
    is_binary = None  # For v6

    def serialize(self, data):
        return data

    def parse(self, data_bytes):
        return data_bytes, b""


# (We actually don't need to extend Parser, but we do it anyway)
class JSONParser(Parser):
    # Settings
    is_binary = False

    def serialize(self, data):
        data_str = json.dumps(data)
        data_bytes = data_str.encode('utf8') + b"\x00"
        return data_bytes

    def parse(self, data_bytes):
        if not data_bytes:
            return [], data_bytes
        data_bytes, *unparsed_bytes_list = data_bytes.rsplit(b"\x00", 1)
        unparsed_bytes = unparsed_bytes_list[0] if unparsed_bytes_list else b""
        data_str = data_bytes.decode('utf8')
        data_str_list = data_str.split("\x00")
        result = []
        for data_str in data_str_list:
            data = json.loads(data_str)
            if isinstance(data, list):
                result.extend(data)
            else:
                result.append(data)
        return result, unparsed_bytes


class JSONParserExt(JSONParser):
    def __init__(self, converter_or_factory=None) -> None:
        super().__init__()
        if converter_or_factory:
            self.converter = converter_or_factory() if callable(converter_or_factory) else converter_or_factory

    def serialize(self, data):
        if self.converter:
            data = self.converter.serialize(data)
        data_bytes = super().serialize(data)
        return data_bytes

    def parse(self, data_bytes):
        data, unparsed_bytes = super().parse(data_bytes)
        if self.converter:
            data = self.converter.parse(data)
        return data, unparsed_bytes


class BinaryParser(Parser):
    # Settings
    is_binary = True
    # Byte order for encoded message
    default_byteorder = "big"  # Use network (big-endian) byteorder by default
    use_byteorder_in_data = True
    # Encoding protocol strings with numeral codes
    code_by_str = None
    # Auto generated after code_by_str
    str_by_code = None
    # Default code_by_str for byteorder
    # (0 - use default (big - as network byteorder))
    code_by_byteorder = {
        "big": 1,
        "little": 2,
    }
    byteorder_by_code = {
        1: "big",
        2: "little",
    }

    def __init__(self) -> None:
        super().__init__()
        if self.code_by_str:
            self.str_by_code = {v: k for k, v in self.code_by_str.items()}

    def serialize(self, data):
        byteorder = self.default_byteorder
        # dict/list of dicts -> list of dicts
        data_list = data if isinstance(data, (list, tuple)) else [data]
        # list of dicts -> list of bytes
        result = [self._serialize_item(item, byteorder) for item in data_list]
        # list of bytes -> bytes
        result_bytes = self.serialize_bytes_list(
            result, byteorder, self.use_byteorder_in_data, self.code_by_byteorder)
        return result_bytes

    def parse(self, data_bytes):
        # bytes -> list of bytes
        bytes_list, unparsed_bytes = BinaryParser.parse_bytes_list(
            data_bytes, self.default_byteorder, self.use_byteorder_in_data, self.byteorder_by_code)
        # list of bytes -> list of dicts
        result = [self._parse_item(item_bytes, byteorder)
                  for byteorder, item_bytes in bytes_list]
        return result, unparsed_bytes

    def _serialize_item(self, item, byteorder):
        return item

    def _parse_item(self, item_bytes, byteorder):
        return item_bytes

    # Utility

    # Use "big" endian byteorder as it's default network byteorder.
    @staticmethod
    def serialize_bytes_list(bytes_list, byteorder="big",
                             is_serialize_byteorder=False, code_by_byteorder=None):
        # byteorder_by_code not used if is_serialize_byteorder=False

        if bytes_list is None:
            return b""

        # Add header to each item
        result = []
        for item_bytes in bytes_list:
            # Header
            if is_serialize_byteorder:
                assert code_by_byteorder
                byteorder_code = int(code_by_byteorder.get(byteorder))
                byteorder_bytes = int.to_bytes(byteorder_code, 1, byteorder)
            else:
                byteorder_bytes = b""
            # (Note: length doesn't include 3 bytes for byteorder and length itself)
            length = len(item_bytes)
            length_bytes = int.to_bytes(length, 2, byteorder)
            # Result
            result.append(byteorder_bytes + length_bytes + item_bytes)

        # Join items
        result_bytes = b"".join(result)
        return result_bytes

    @staticmethod
    def parse_bytes_list(data_bytes, default_byteorder="big",
                         is_parse_byteorder=False, byteorder_by_code=None):
        # byteorder_by_code not used if is_parse_byteorder=False

        if not data_bytes:
            return None, b""

        result = []
        cursor = 0
        data_len = len(data_bytes)
        while cursor < data_len:
            cursor_start = cursor
            # Header
            if is_parse_byteorder:
                # (As we get only 1 byte, byteorder here doesn't matter)
                byteorder_code = int.from_bytes(data_bytes[cursor:cursor + 1], default_byteorder)
                byteorder = byteorder_by_code.get(byteorder_code, default_byteorder)
                cursor += 1
            else:
                byteorder = default_byteorder
            # (Note: length doesn't include 2-3 first bytes for byteorder and length itself)
            length = int.from_bytes(data_bytes[cursor:cursor + 2], byteorder)
            cursor += 2
            if cursor + length > data_len:
                return result, data_bytes[cursor_start:]
            # Result
            result.append((byteorder, data_bytes[cursor:cursor + length]))
            cursor += length

        return result, b""

    @staticmethod
    def serialize_int_list(items, item_length, byteorder, signed=False):
        if items is None:
            return b""
        bytes_list = [int.to_bytes(item, item_length, byteorder, signed=signed)
                      for item in items]
        items_bytes = b"".join(bytes_list)
        # length_bytes = int.to_bytes(len(items_bytes), 2, byteorder)
        # return length_bytes + items_bytes
        return items_bytes

    @staticmethod
    def parse_int_list(data_bytes, item_length, byteorder, signed=False):
        # Return list of tuples: [(byteorder, bytes), (byteorder, bytes), ...]
        if not data_bytes:
            return None
        item_count = len(data_bytes) / item_length
        assert int(item_count) == item_count, f"{item_count}={len(data_bytes)}/{item_length}"
        items = [int.from_bytes(data_bytes[i:i + item_length], byteorder, signed=signed)
                 for i in range(0, len(data_bytes), item_length)]
        return items
