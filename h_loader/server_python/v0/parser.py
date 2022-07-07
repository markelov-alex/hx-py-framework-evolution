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


# Changes:
#  - add "*" for default any command in fields_by_code.
class DataConverter(Parser):
    # Settings
    code_index = 0
    code_field = "code"

    def __init__(self) -> None:
        super().__init__()
        self.fields_by_code = {}

    # dicts -> lists
    def serialize(self, data):
        commands = self.to_command_list(data)

        result = []
        for command in commands:
            if isinstance(command, dict):
                code = command.get(self.code_field)
                fields = self.fields_by_code.get(code)
                if not fields:
                    fields = self.fields_by_code.get("*")
                if fields:
                    command = [command.get(f) for f in fields]
            result.append(command)
        return result

    # lists -> dicts
    def parse(self, data):
        commands = self.to_command_list(data)

        result = []
        for command in commands:
            com_len = len(command)
            if isinstance(command, list):
                code = command[self.code_index] if self.code_index < com_len else None
                fields = self.fields_by_code.get(code)
                if not fields:
                    fields = self.fields_by_code.get("*")
                if fields:
                    command = {f: command[i] if i < com_len else None
                               for i, f in enumerate(fields)}
            result.append(command)
        return result

    @staticmethod
    def to_command_list(data):
        # To list of commands
        # "a" -> ["a"]
        # {"a": 1} -> [{"a": 1}]
        commands = data if isinstance(data, list) else [data]
        # ["a", "b"] -> [["a", "b"]] (where ["a", "b"] is one command)
        if len(commands) > 1 and not isinstance(commands[0], (list, dict)):
            commands = [commands]
        return commands


# Changes:
#  - create init() to set up codes in instance lookups, not static ones.
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
    code_by_byteorder = None
    byteorder_by_code = None

    def __init__(self) -> None:
        super().__init__()
        self.init()
        if self.code_by_str:
            self.str_by_code = {v: k for k, v in self.code_by_str.items()}

    # Override to change codes
    def init(self):
        self.code_by_str = {}
        # (0 - use default (big - as network byteorder))
        self.code_by_byteorder = {
            "big": 1,
            "little": 2,
        }
        self.byteorder_by_code = {
            1: "big",
            2: "little",
        }

    def serialize(self, data):
        # Serialize (list of dicts or dict -> bytes)
        result = self._serialize_commands(data)
        # Add length field before bytes (bytes -> bytes)
        return BinaryParser.serialize_bytes_list([result])

    def _serialize_commands(self, data):
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
        # Remove length field (bytes -> list of bytes)
        bytes_list, unparsed_bytes = BinaryParser.parse_bytes_list(data_bytes)
        # Parse (list of bytes -> list of commands)
        result = []
        for bo, b in bytes_list:
            result.extend(self._parse_commands(b)[0])
        return result, unparsed_bytes

    def _parse_commands(self, data_bytes):
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


class MultiParser(Parser):
    # Settings
    # (All versions should be in bytes)
    default_version = None
    parser_or_factory_by_version = None

    # State
    _output_version = None
    _input_version = None
    _output_parser = None
    _input_parser = None
    is_output_binary = None
    is_input_binary = None

    @property
    def version(self):
        return self.output_version

    # @version.setter
    # def version(self, value):
    #     self.output_version = value

    @property
    def output_version(self):
        return self._output_version

    @output_version.setter
    def output_version(self, value):
        if self._output_version != value and value in self.parser_or_factory_by_version:
            print(f"Output version changed: {self._output_version} -> {value}")
            self._output_version = value
            parser = self.parser_or_factory_by_version.get(value)
            self._output_parser = parser() if callable(parser) else parser
            self.is_output_binary = self._output_parser.is_binary

    @property
    def input_version(self):
        return self._input_version

    @input_version.setter
    def input_version(self, value):
        if self._input_version != value and value in self.parser_or_factory_by_version:
            print(f"Input version changed: {self._input_version} -> {value}")
            self._input_version = value
            parser = self.parser_or_factory_by_version.get(value)
            self._input_parser = parser() if callable(parser) else parser
            self.is_input_binary = self.is_binary = self._input_parser.is_binary

    def __init__(self) -> None:
        super().__init__()
        self.output_version = self.default_version
        self.input_version = self.default_version
        self.pending_versions = []
        self.parsed_versions = []

        # Check all versions are set as bytes
        for v in [self.default_version] + list(self.parser_or_factory_by_version):
            if not isinstance(v, bytes):
                raise Exception(f"All version values should be bytes! Not bytes: {v}")

    def serialize(self, data):
        if not data:
            return b""
        data_list = data if isinstance(data, list) else [data]
        result = b""
        last_i = 0

        # Find version in data
        for i, d in enumerate(data_list):
            if isinstance(d, bytes) and d in self.parser_or_factory_by_version:
                # Version data found
                version = d
                # Serialize data before version
                prev = data_list[last_i:i]
                last_i = i + 1
                if prev:
                    result += self._output_parser.serialize(prev)
                if self.output_version == version:
                    # Skip if same version
                    continue
                # Serialize version
                result += self._serialize_version(version)
                # (After serialization)
                self.output_version = version
                # Add to pending_versions only those version which change was
                # initiated on server side, not on client (parsed_versions)
                if version in self.parsed_versions:
                    print(f" (Remove version: {version} from parsed: {self.parsed_versions})")
                    self.parsed_versions.remove(version)
                else:
                    print(f" (Add version: {version} to pending: {self.pending_versions})")
                    self.pending_versions.append(version)

        # (Can be set by _serialize_version(), so place here)
        if not self._output_parser:
            print(f"Error! No valid version is selected, so data: {data} cannot be serialized!")
            return None

        # Serialize data after version (or all data if there is no version)
        rest = data_list[last_i:]
        if rest:
            result += self._output_parser.serialize(rest)
        return result

    def parse(self, data_bytes):
        # Parse data_bytes switching between versions on the fly.
        # That is possible because we use two fixed format over all other protocols:
        #  - for binary format we add message length before it,
        #  - for string format we add zero-byte (\x00) to the end of each message.
        # That's how we separate messages when they joined together in the buffer.
        # Version data should occupy the whole message.
        #
        # Supposed, that versions are known in both server and client side.
        # If you need to know all supported versions, please create special command
        # as part of your own protocol by yourself.

        if not self._input_parser:
            print(f"Error! No valid input_version is selected, "
                  f"so data_bytes: {data_bytes} cannot be parsed!")
            return [], b""

        # Find and extract version data
        result = []
        self.parsed_versions = []
        while data_bytes:
            version, prev_bytes, data_bytes = self._parse_next_version(data_bytes)

            if version:
                # Parse data before version with previous parser
                if prev_bytes:
                    print(f"Parse prev_bytes: {prev_bytes} with previous version: {self.input_version}")
                    result.extend(self._input_parser.parse(prev_bytes)[0])
                    print(f"Parse prev_bytes: {prev_bytes} with previous version: {self.input_version} result: {result}")
                # Change version
                self.input_version = version
                if version in self.pending_versions:
                    # Parsed version that was initially set by server,
                    # so don't send it to client again.
                    # Needed to prevent infinite circling between client and server
                    print(f" (Remove version: {version} from pending: {self.pending_versions})")
                    self.pending_versions.remove(version)
                else:
                    # Parsed_versions needed to do not add versions from client to
                    # pending_versions
                    print(f" (Add version: {version} to parsed: {self.parsed_versions})")
                    self.parsed_versions.append(version)
                    # Parsed version was initially set by client,
                    # so send it back to change client's input_version
                    print(f" (To be resent version: {version})")
                    result.append(version)
            else:
                # No more version data in data_bytes
                break

        # Parse with last chosen version parser
        unparsed_bytes = b""
        if data_bytes:
            r, unparsed_bytes = self._input_parser.parse(data_bytes)
            result.extend(r)
            print(f"Parse bytes: {data_bytes} with version: {self.input_version} "
                  f"result: {r} unparsed_bytes: {unparsed_bytes}")
        return result, unparsed_bytes

    def _serialize_version(self, version):
        byteorder = "big"
        if self.is_output_binary:
            length_bytes = int.to_bytes(len(version), 2, byteorder)
            return length_bytes + version
        return version + b"\x00"

    def _parse_next_version(self, data_bytes):
        byteorder = "big"
        version = None
        prev_bytes = None
        if self._input_parser and self._input_parser.is_binary:
            # Binary protocol
            cursor = 0
            data_len = len(data_bytes)
            while not version and cursor < data_len:
                prev_end = cursor
                length = int.from_bytes(data_bytes[cursor:cursor + 2], byteorder)
                cursor += 2
                b = data_bytes[cursor:cursor + length]
                cursor += length
                next_start = cursor
                if b in self.parser_or_factory_by_version:
                    version = b
                    if prev_end > 0:
                        prev_bytes = data_bytes[:prev_end]
                    data_bytes = data_bytes[next_start:]
                    break
        else:
            # String protocol
            parts = data_bytes.split(b"\x00")
            for i, part in enumerate(parts):
                if part in self.parser_or_factory_by_version:
                    version = part
                    prev_bytes = b"\x00".join(parts[:i])
                    if prev_bytes:
                        prev_bytes += b"\x00"
                    data_bytes = b"\x00".join(parts[i + 1:])
                    break
        return version, prev_bytes, data_bytes
