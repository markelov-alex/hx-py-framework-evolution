import traceback


# Changes:
#  - add index for choosing own parser for each connection,
#  - add commands_handler.
class Game:
    # Settings
    parser_factory = None
    commands_handler = None

    def __init__(self, parser_factory=None, commands_handler=None) -> None:
        super().__init__()
        if parser_factory:
            self.parser_factory = parser_factory
        if commands_handler:
            self.commands_handler = commands_handler

        if not callable(self.parser_factory):
            raise Exception("Parser_factory should be callable (function or class)!")

        # State
        self.parser_by_index = {}

    # As parser now contains the state (version, current-parser) each connection
    # should have its own parser
    def on_connect(self, index):
        self.parser_by_index[index] = self.parser_factory()

    def on_disconnect(self, index):
        del self.parser_by_index[index]

    # bytes -> bytes
    def process_bytes(self, index, request_bytes):
        unparsed_bytes = b""
        result = []
        if request_bytes == b"<policy-file-request/>\x00":
            response_bytes = b"<cross-domain-policy>" \
                             b'<allow-access-from domain="*" to-ports="*"/>' \
                             b"</cross-domain-policy>\x00"
            result.append((index, response_bytes))
        else:
            parser = self.parser_by_index[index]
            try:
                request_data, unparsed_bytes = parser.parse(request_bytes)
                print(f"[SERVER#{index}]  Received parsed: {repr(request_data)} "
                      f"{'unparsed: ' + repr(unparsed_bytes) if unparsed_bytes else ''}")
                commands = request_data if isinstance(request_data, list) else[request_data]
                response_data, to_all_data = self.handle_commands(index, commands)
            except Exception as e:
                print(f"[SERVER#{index}] Error while parsing or processing: {traceback.format_exc()}")
                response_data, to_all_data = {"error": str(e)}, None

            print(f"[SERVER#{index}]  Sending: {repr(response_data)} as response "
                  f"and commands: {repr(to_all_data)}")
            if response_data:
                response_bytes = parser.serialize(response_data) if response_data else None
                result.append((index, response_bytes))
            if to_all_data:
                # Simple, but not efficient:
                # same parser could process same data several times
                # for i in index:
                #     p = self.parser_by_index[i]
                #     to_all_bytes = p.serialize(to_all_data)
                #     result.append((i, to_all_bytes))
                # Use caching same data for same parser
                bytes_by_parser = {}
                for i, p in self.parser_by_index.items():
                    to_all_bytes = bytes_by_parser.get(p)  # (Cached)
                    if to_all_bytes is None:
                        # (Serialize and cache)
                        bytes_by_parser[p] = to_all_bytes = p.serialize(to_all_data)
                    result.append((i, to_all_bytes))
        return result, unparsed_bytes

    def handle_commands(self, index, commands):
        if self.commands_handler:
            # todo
            # response_commands, commands_to_all = self.commands_handler(index, commands)
            # for compatibility
            response_commands, commands_to_all = self.commands_handler(commands)
        else:
            response_commands, commands_to_all = commands, []
        return response_commands, commands_to_all
