from v4.game import Game
from v4.parser import DataConverter, JSONParserExt


class CustomConverter(DataConverter):
    # Settings
    code_index = 0
    code_field = "code"

    def __init__(self) -> None:
        super().__init__()
        self.fields_by_code = {
            "set": ["code", "name", "data"],
            "update": ["code", "name", "data"],
        }


class CustomJSONParser(JSONParserExt):
    converter = CustomConverter()


class CustomGame(Game):
    parser = CustomJSONParser()

    def __init__(self, parser=None, commands_handler=None) -> None:
        super().__init__(parser, commands_handler)
        # Game state
        self.storage = {}

    def handle_commands(self, commands):
        if not commands:
            return commands, []
        response_commands = []
        commands_to_all = []
        for command in commands:
            if not isinstance(command, dict):
                continue
            code = command.get("code")
            if code == "get":
                name = command.get("name")
                response_commands.append({
                    "code": "set",
                    "name": name,
                    "data": self.storage.get(name)
                })
            elif code == "update":
                name = command.get("name")
                data = command.get("data")
                # (Get or create empty)
                cur_data = self.storage[name] = self.storage.get(name, [])
                # (Update)
                update(cur_data, data)
                # print(f"Storage changed: {storage}")
                # (Send command unchanged to all connections)
                commands_to_all.append(command)
        return response_commands, commands_to_all


def update(target, source):
    # target = [[1, 2, 3], [4, 5, 6]]
    # source = {"0": {"1": 7}}
    # will change target: [[1, 7, 3], [4, 5, 6]]
    for k, v in source.items():
        if k.isdigit():
            k = int(k)
            add_count = k - len(target) + 1
            if add_count > 0:
                target.extend([-1] * add_count)
            if isinstance(v, dict):
                if target[k] == -1:
                    target[k] = []
                update(target[k], v)
            else:
                target[k] = v
