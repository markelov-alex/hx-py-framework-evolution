import traceback

from v0.game import Game as Game0


class Game(Game0):

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
                responses_and_indexes_list = self.handle_commands(index, commands)
            except Exception as e:
                print(f"[SERVER#{index}] Error while parsing or processing: {traceback.format_exc()}")
                responses_and_indexes_list = [([{"error": str(e)}], [index])]

            print(f"[SERVER#{index}]  Sending: {repr(responses_and_indexes_list)}")
            for responses, indexes in responses_and_indexes_list:
                if not responses:
                    continue
                bytes_by_version = {}
                for index in indexes:
                    parser = self.parser_by_index.get(index)
                    version = parser.output_version if hasattr(parser, "output_version") else parser
                    response_bytes = bytes_by_version.get(version)
                    if response_bytes is None:
                        bytes_by_version[version] = response_bytes = parser.serialize(responses)
                    if response_bytes:
                        result.append((index, response_bytes))
            print(f"[SERVER#{index}]  Sending serialized: {repr(result)}")
        return result, unparsed_bytes

    def handle_commands(self, index, commands):
        if self.commands_handler:
            response_commands = self.commands_handler(index, commands)
        else:
            response_commands = [(commands, [index])]
        return response_commands
