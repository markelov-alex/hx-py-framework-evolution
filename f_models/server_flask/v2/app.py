import json
import os

from flask import Flask, send_file, request
from markupsafe import escape

# Refactoring (Extract function)

print("http v2")
app = Flask(__name__)


@app.route("/crossdomain.xml")
def crossdomain():
    return send_file("crossdomain.xml")


@app.route("/storage/<key>")
def storage(key):
    key = escape(key)
    values = request.values
    method = values.get("_method") or request.method
    if method == "POST":
        # Save
        state, = parse(values, ["state"])
        if state is not None:
            save(key, state)
            return {"success": True}
        return {"success": False}
    elif method == "GET":
        # Load
        state = load(key)
        if state is None:
            return {"success": False}
        return {"success": True, "state": state}
    elif method == "PATCH":
        # Update
        data, index, value = parse(values, ("", "index", "value"))
        if not isinstance(index, int) or not isinstance(value, int):
            return False
        state = load(key)
        if state is None:
            state = []
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        save(key, state)
        return {"success": True, **data}
    return None


def parse(values, names):
    data_str = values.get("data")
    if not data_str:
        return [None for n in names]
    data = json.loads(data_str)
    return [data.get(n) if n else data for n in names]


def load(key):
    filename = "../data/save_" + key
    if not os.path.exists(filename):
        return None
    with open(filename, "r") as f:
        state = json.load(f)
        print("load", state)
        return state


def save(key, data):
    filename = "../data/save_" + key
    dirname = os.path.dirname(filename)
    if dirname and not os.path.exists(dirname):
        os.makedirs(dirname)
    with open(filename, "w") as f:
        json.dump(data, f)
        print("save", data)
