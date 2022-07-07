import json
import os

from flask import Flask, send_file, request
from markupsafe import escape

# Extract Application

print("http v4")
app = Flask(__name__)


@app.route("/crossdomain.xml")
def crossdomain():
    return send_file("crossdomain.xml")


@app.route("/storage/<key>")
def storage(key):
    key = escape(key)
    application = MyApplication(key)
    values = request.values
    method = values.get("_method") or request.method
    if method == "POST":
        return application.save(values)
    elif method == "GET":
        return application.get(values)
    elif method == "PATCH":
        return application.update(values)
    return None


class MyApplication:
    def __init__(self, key):
        self.service = FileService("../data/save_")
        self.key = key

    def get(self, values):
        state = self.service.load(self.key)
        if state is None:
            return {"success": False}
        return {"success": True, "state": state}

    def save(self, values):
        state, = self.parse(values, ["state"])
        if state is not None:
            self.service.save(self.key, state)
            return {"success": True}
        return {"success": False}

    def update(self, values):
        data, index, value = self.parse(values, ("", "index", "value"))
        if not isinstance(index, int) or not isinstance(value, int):
            return False
        state = self.service.load(self.key)
        if state is None:
            state = []
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        self.service.save(self.key, state)
        return {"success": True, **data}

    def parse(self, values, names):
        data_str = values.get("data")
        if not data_str:
            return [None for n in names]
        data = json.loads(data_str)
        return [data.get(n) if n else data for n in names]


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
