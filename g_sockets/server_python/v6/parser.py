from v5.parser import Parser, BinaryParser as BinaryParserOld


class BinaryParser(BinaryParserOld):

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
        for b in bytes_list:
            result.extend(super().parse(b)[0])
        return result, unparsed_bytes


class MultiParser(Parser):
    # Settings
    # (All versions should be in bytes)
    default_version = None
    parser_or_factory_by_version = None

    # State
    _version = None
    current = None

    @property
    def version(self):
        return self._version

    @version.setter
    def version(self, value):
        if self._version != value and value in self.parser_or_factory_by_version:
            print(f"Version changed: {self._version} -> {value}")
            self._version = value
            parser = self.parser_or_factory_by_version.get(value)
            self.current = parser() if callable(parser) else parser
            self.is_binary = self.current.is_binary

    def __init__(self) -> None:
        super().__init__()
        self.version = self.default_version

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
                # Serialize data before version
                prev = data_list[last_i:i]
                if prev:
                    result += self.current.serialize(prev)
                # Serialize version
                result += self._serialize_version(d)
                last_i = i + 1

        # (Can be set by _serialize_version(), so place here)
        if not self.current:
            print(f"Error! No valid version is selected, so data: {data} cannot be serialized!")
            return None

        # Serialize data after version (or all data if there is no version)
        rest = data_list[last_i:]
        if rest:
            result += self.current.serialize(rest)
        return result

    def parse(self, data_bytes):
        if not data_bytes:
            return [], b""
        if not self.current:
            print(f"Error! No valid version is selected, so data_bytes: {data_bytes} cannot be parsed!")
            return [], b""
        return self.current.parse(data_bytes)

    def _serialize_version(self, version):
        byteorder = "big"
        if self.is_binary:
            length_bytes = int.to_bytes(len(version), 2, byteorder)
            return length_bytes + version
        return version + b"\x00"


class AutoMultiParser(MultiParser):

    def _serialize_version(self, version):
        result = super()._serialize_version(version)
        # (After serialization)
        self.version = version
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

        # Find and extract version data
        result = []
        while data_bytes:
            version, prev_bytes, data_bytes = self._parse_next_version(data_bytes)

            if version:
                # Parse data before version with previous parser
                if prev_bytes:
                    print(f"Parse prev_bytes: {prev_bytes} with previous version: {self.version}")
                    result.extend(super().parse(prev_bytes)[0])
                    print(f"Parse prev_bytes: {prev_bytes} with previous version: {self.version} result: {result}")
                # Change version
                self.version = version
                # # Return current version to send it to client
                # # (can be different than initially parsed version)
                # result.append(self.version)
            else:
                # No more version data in data_bytes
                break

        # Parse with last chosen version parser
        unparsed_bytes = b""
        if data_bytes:
            r, unparsed_bytes = super().parse(data_bytes)
            result.extend(r)
            print(f"Parse bytes: {data_bytes} with version: {self.version} result: {r} "
                  f"unparsed_bytes: {unparsed_bytes}")
        return result, unparsed_bytes

    def _parse_next_version(self, data_bytes):
        byteorder = "big"
        version = None
        prev_bytes = None
        if self.current and self.current.is_binary:
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
