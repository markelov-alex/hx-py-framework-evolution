import json
import os

from flask import Flask, send_file, request
from markupsafe import escape

# Move to commands

print("http v6")
app = Flask(__name__)


@app.route("/crossdomain.xml")
def crossdomain():
    return send_file("crossdomain.xml")


@app.route("/storage/<key>")
def storage(key):
    application = MyApplication(key)
    return application.handle(request)


class FlaskParser:
    command_by_alias = {
        "GET": "get",
        "POST": "save",
        "PATCH": "update",
    }

    def parse_command(self, request):
        values = request.values
        data_str = values.get("data")
        data = json.loads(data_str) if data_str else {}
        method = data.get("code")
        if not method:
            method = values.get("_method") or request.method
        command = self.command_by_alias.get(method, escape(method))
        return command, data, values

    def parse(self, data, names):
        if not data:
            return [None for n in names]
        return [data.get(n) if n else data for n in names]

    def response(self, success, data, values):
        data = {} if data is None else data
        assert values is not None
        return {"success": success, **data, "version": "v6"}


class MyLogic:
    def __init__(self, service):
        self.service = service

    def get(self, key):
        return self.service.load(key)

    def save(self, key, state):
        if state is None:
            return False
        self.service.save(key, state)
        return True

    def update(self, key, index, value):
        state = self.service.load(key)
        if not isinstance(index, int) or not isinstance(value, int):
            return False
        if state is None:
            state = []
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        self.service.save(key, state)
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
        filename = self.filename_prefix + key
        dirname = os.path.dirname(filename)
        if dirname and not os.path.exists(dirname):
            os.makedirs(dirname)
        with open(filename, "w") as f:
            json.dump(data, f)
            f.flush()
            print("save", data)

    def load(self, key):
        filename = self.filename_prefix + key
        if not os.path.exists(filename):
            return None
        with open(filename, "r") as f:
            data = json.load(f)
            print("load", data)
            return data


# More looks like Controller with handle() method
class MyApplication:
    # Settings
    parser_factory = FlaskParser
    service_factory = lambda self: FileService("../data/save_")
    logic_factory = MyLogic

    def __init__(self, key):
        self.key = escape(key)
        self.parser = self.parser_factory()
        self.service = self.service_factory()
        self.logic = self.logic_factory(self.service)

    # v1
    def _handle(self, request):
        command, data, values = self.parser.parse_command(request)
        key = data.get("key") or self.key
        if command == "save" or command == "set":
            return self.save(key, data, values)
        elif command == "get":
            return self.get(key, data, values)
        elif command == "update":
            return self.update(key, data, values)
        return None

    # v2
    def handle(self, request):
        command, data, values = self.parser.parse_command(request)
        key = data.get("key") or self.key
        fun = getattr(self, command)
        if fun is not None:
            return fun(key, data, values)
        return None

    def get(self, key, data, values):
        state = self.logic.get(key)
        return self.parser.response(state is not None, {**data, "state": state}, values)

    def set(self, key, data, values):
        return self.save(key, data, values)

    def save(self, key, data, values):
        state, = self.parser.parse(data, ["state"])
        result = self.logic.save(key, state)
        return self.parser.response(result, data, values)

    def update(self, key, data, values):
        data, index, value = self.parser.parse(data, ("", "index", "value"))
        result = self.logic.update(key, index, value)
        return self.parser.response(result, data, values)
