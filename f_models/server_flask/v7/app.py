import json
import os

from flask import Flask, send_file, request
from markupsafe import escape

# Refactoring for unification with socket server v3

print("http v7")

# Server-specific

app = Flask(__name__)


@app.route("/crossdomain.xml")
def crossdomain():
    return send_file("crossdomain.xml")


@app.route("/storage/<key>")
def storage(key):
    return application.handle_request(key, request)


class FlaskApplication:
    def __init__(self, parser, default_controller, controller_by_key=None):
        super().__init__()
        self.parser = parser
        self.default_controller = default_controller
        self.controller_by_key = controller_by_key or {}

    def handle_request(self, key, request):
        command, _ = self.parser.parse(request)
        controller = self.controller_by_key.get(key, self.default_controller)
        result = controller.handle_command(command)
        return self.parser.serialize(result)

    # def handle_request(self, key, request):
    #     commands, _ = self.parser.parse(request)
    #     result = []
    #     for command in commands:
    #         controller = self.controller_by_key.get(key, self.default_controller)
    #         result.extend(controller.handle_command(command))
    #     return self.parser.serialize(result)


class Parser:
    def parse(self, request):
        return request, b""  # b"" - unparsed_bytes to unify with sockets

    def serialize(self, response):
        return response


class FlaskParser(Parser):
    command_by_alias = {
        "GET": "get",
        "POST": "save",
        "PATCH": "update",
    }

    def parse(self, request):
        # Parse
        values = request.values
        data_str = values.get("data")
        data = json.loads(data_str) if data_str else None
        if data is None:
            data = {}
        # Prepare command
        code = data.get("code")
        if not code:
            code = values.get("_method") or request.method
        data["code"] = self.command_by_alias.get(code, code)
        data["key"] = request.view_args.get("key")
        # if not isinstance(data, list):
        #     data = [data]
        return data, b""

    # No real serialization, just prepare response
    def serialize(self, command):
        if command:
            command["version"] = "v6"  # Not "v7"
        return command


# Application-specific

class MyController:
    # Settings
    service_factory = lambda self: FileService("../data/save_")
    # model_factory = MyModel  # Error: Unresolved reference
    model_factory = lambda self, *args: MyModel(*args)

    def __init__(self):
        self.service = self.service_factory()
        self.model = self.model_factory(self.service)

    # v1
    def _handle_command(self, command):
        code = command.get("code")
        key = command.get("key")
        result = None
        if code == "save" or code == "set":
            result = self.save(key, command)
        elif code == "load" or code == "get":
            result = self.get(key, command)
        elif code == "update":
            result = self.update(key, command)
        return result

    # v2
    def handle_command(self, command):
        key = command.get("key")
        code = command.get("code")
        fun = getattr(self, escape(code))
        result = fun(key, command) if fun is not None else None
        return result

    def get(self, key, command):
        return self.load(key, command)

    def set(self, key, command):
        return self.save(key, command)

    def load(self, key, command):
        state = self.service.load(key)
        return {**command, "success": True, "state": state}

    def save(self, key, command):
        state = command.get("state")
        result = self.service.save(key, state)
        return {**command, "success": result}

    def update(self, key, command):
        index = command.get("index")
        value = command.get("value")
        state = self.service.load(key)
        result = self.model.update(state, index, value)
        self.service.save(key, state)
        return {**command, "success": result}


class MyModel:
    def update(self, state, index, value):
        if not isinstance(index, int) or not isinstance(value, int):
            return False
        if state is None:
            state = []
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        return True


class StorageService:
    def save(self, key, data):
        pass

    def load(self, key):
        return None


class FileService(StorageService):
    filename_prefix = ""

    def __init__(self, filename_prefix=None):
        self.filename_prefix = filename_prefix or self.filename_prefix

    def save(self, key, data):
        key = escape(key)
        filename = self.filename_prefix + key
        dirname = os.path.dirname(filename)
        if dirname and not os.path.exists(dirname):
            assert self.check_cwd()
            os.makedirs(dirname)
        with open(filename, "w") as f:
            json.dump(data, f)
            f.flush()
            print("save", data)

    def load(self, key):
        key = escape(key)
        filename = self.filename_prefix + key
        if not os.path.exists(filename):
            assert self.check_cwd()
            return None
        with open(filename, "r") as f:
            data = json.load(f)
            print("load", data)
            return data

    def check_cwd(self):
        cwd = os.getcwd()
        cwd_dirs = cwd.split("/")
        if cwd_dirs[-1].startswith("v"):
            print(f"Wrong current working directory: {cwd}! Should not be v1, v2, etc.")
            return True


application = FlaskApplication(FlaskParser(), MyController())
