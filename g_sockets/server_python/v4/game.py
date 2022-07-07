import traceback


class Game:
    def __init__(self, parser=None) -> None:
        super().__init__()
        if parser:
            self.parser = parser

    # bytes -> bytes
    def process_bytes(self, request_bytes):
        if request_bytes == b"<policy-file-request/>":
            response_bytes = b"<cross-domain-policy>" \
                             b'<allow-access-from domain="*" to-ports="*"/>' \
                             b"</cross-domain-policy>"
            to_all_bytes = None
        else:
            try:
                request_data = self.parser.parse(request_bytes)
                commands = request_data if isinstance(request_data, list) else[request_data]
                response_data, to_all_data = self.handle_commands(commands)
            except Exception as e:
                print(f"[SERVER] Error while parsing or processing: {traceback.format_exc()}")
                response_data, to_all_data = {"error": str(e)}, None
            response_bytes = self.parser.serialize(response_data) if response_data else None
            to_all_bytes = self.parser.serialize(to_all_data) if to_all_data else None
        return response_bytes, to_all_bytes

    def handle_commands(self, commands):
        response_commands, commands_to_all = commands, []
        return response_commands, commands_to_all
