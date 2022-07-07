import traceback


# Changes:
#  - return also unparsed_bytes,
#  - add index to process_bytes() (for logs, and later for v6).

class Game:
    def __init__(self, parser_or_factory=None, commands_handler=None) -> None:
        super().__init__()
        if parser_or_factory:
            self.parser = parser_or_factory() if callable(parser_or_factory) else parser_or_factory
        if commands_handler:
            self.handle_commands = commands_handler

    # bytes -> bytes
    def process_bytes(self, index, request_bytes):
        unparsed_bytes = b""
        if request_bytes == b"<policy-file-request/>\x00":
            response_bytes = b"<cross-domain-policy>" \
                             b'<allow-access-from domain="*" to-ports="*"/>' \
                             b"</cross-domain-policy>\x00"
            to_all_bytes = None
        else:
            try:
                request_data, unparsed_bytes = self.parser.parse(request_bytes)
                print(f"[SERVER#{index}]  Received parsed: {repr(request_data)} "
                      f"{'unparsed: ' + repr(unparsed_bytes) if unparsed_bytes else ''}")
                commands = request_data if isinstance(request_data, list) else[request_data]
                response_data, to_all_data = self.handle_commands(commands)
            except Exception as e:
                print(f"[SERVER] Error while parsing or processing: {traceback.format_exc()}")
                response_data, to_all_data = {"error": str(e)}, None

            print(f"[SERVER#{index}]  Sending: {repr(response_data)} as response "
                  f"and commands: {repr(to_all_data)}")
            response_bytes = self.parser.serialize(response_data) if response_data else None
            to_all_bytes = self.parser.serialize(to_all_data) if to_all_data else None
        return response_bytes, to_all_bytes, unparsed_bytes

    def handle_commands(self, commands):
        response_commands, commands_to_all = commands, []
        return response_commands, commands_to_all
