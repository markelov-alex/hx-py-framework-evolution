import json
import os

from flask import Flask, send_file, request
from markupsafe import escape

# Extract Parser and Logic
# (Important: Use with client v5)

print("http v5")
app = Flask(__name__)


@app.route("/crossdomain.xml")
def crossdomain():
    return send_file("crossdomain.xml")


@app.route("/storage/<key>")
def storage(key):
    key = escape(key)
    application = MyApplication()
    values = request.values
    method = values.get("_method") or request.method
    if method == "POST":
        return application.save(key, values)
    elif method == "GET":
        return application.get(key, values)
    elif method == "PATCH":
        return application.update(key, values)
    return None


class FlaskParser:
    def parse(self, values, names):
        data_str = values.get("data")
        if not data_str:
            return [None for n in names]
        data = json.loads(data_str)
        return [data.get(n) if n else data for n in names]

    def response(self, success, data, values):
        data = {} if data is None else data
        assert values is not None
        return {"success": success, **data, "_method": values.get("_method"),
                "version": "v5"}


class MyModel:
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
        if not isinstance(index, int) or not isinstance(value, int):
            return False
        state = self.service.load(key)
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
            print("save", data)

    def load(self, key):
        filename = self.filename_prefix + key
        if not os.path.exists(filename):
            return None
        with open(filename, "r") as f:
            state = json.load(f)
            print("load", state)
            return state


class MyApplication:
    # Settings
    parser_factory = FlaskParser
    service_factory = lambda self: FileService("../data/save_")
    model_factory = MyModel

    def __init__(self) -> None:
        super().__init__()
        self.parser = self.parser_factory()
        self.service = self.service_factory()
        self.model = self.model_factory(self.service)

    def get(self, key, values):
        state = self.model.get(key)
        return self.parser.response(state is not None, {"state": state}, values)

    def save(self, key, values):
        state = self.parser.parse(values, ["state"])
        result = self.model.save(key, state)
        return self.parser.response(result, None, values)

    def update(self, key, values):
        data, index, value = self.parser.parse(values, ("", "index", "value"))
        result = self.model.update(key, index, value)
        return self.parser.response(result, data, values)
