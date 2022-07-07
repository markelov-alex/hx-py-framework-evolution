from v5.parser import Parser


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
                # Parsed_versions needed to do not add versions from client to
                # pending_versions
                print(f" (Add version: {version} to parsed: {self.parsed_versions})")
                self.parsed_versions.append(version)
                if version in self.pending_versions:
                    # Parsed version that was initially set by server,
                    # so don't send it to client again.
                    # Needed to prevent infinite circling between client and server
                    print(f" (Remove version: {version} from pending: {self.pending_versions})")
                    self.pending_versions.remove(version)
                else:
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
