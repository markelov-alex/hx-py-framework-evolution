import json


class Parser:
    def serialize(self, data):
        return data

    def parse(self, data_bytes):
        return data_bytes


class JSONParser(Parser):
    def serialize(self, data):
        data_str = json.dumps(data)
        data_bytes = data_str.encode('utf8')
        return data_bytes

    def parse(self, data_bytes):
        data_str = data_bytes.decode('utf8')
        data = json.loads(data_str)
        return data


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
        data = super().parse(data_bytes)
        if self.converter:
            data = self.converter.parse(data)
        return data


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
                if fields:
                    command = {f: command[i] if i < com_len else None
                               for i, f in enumerate(fields)}
            result.append(command)
        return result

    @staticmethod
    def to_command_list(data):
        # To list of commands
        # "a" -> ["a"], {"a": 1} -> [{"a": 1}]
        commands = data if isinstance(data, list) else [data]
        # ["a", "b"] -> [["a", "b"]] (where ["a", "b"] is one command)
        if len(commands) > 1 and not isinstance(commands[0], (list, dict)):
            commands = [commands]
        return commands
