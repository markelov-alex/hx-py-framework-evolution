import json
import os

from flask import Flask, send_file, request
from markupsafe import escape

# The very naive version of our HTTP server (built on Flask)

print("http v1")
app = Flask(__name__)


@app.route("/crossdomain.xml")
def crossdomain():
    return send_file("crossdomain.xml")


@app.route("/storage/<key>")
def storage(key):
    key = escape(key)
    filename = "../data/save_" + key
    dirname = os.path.dirname(filename)
    if dirname and not os.path.exists(dirname):
        os.makedirs(dirname)
    values = request.values
    method = values.get("_method") or request.method
    if method == "POST":
        # Save
        data_str = values.get("data")
        if data_str:
            with open(filename, "w") as f:
                data = json.loads(data_str)
                json.dump(data.get("state"), f)
                # f.write(data_str)
                print("save", data.get("state"))
                return {"success": True}
        return {"success": False}
    elif method == "GET":
        # Load
        if not os.path.exists(filename):
            return {"success": False}
        with open(filename, "r") as f:
            state = json.load(f)
            print("load", state)
            return {"success": True, "state": state}
    elif method == "PATCH":
        # Update
        data_str = values.get("data")
        data = json.loads(data_str) if data_str else None
        index = data.get("index") if data else None
        value = data.get("value") if data else None
        if not isinstance(index, int) or not isinstance(value, int):
            return {"success": False}
        if not os.path.exists(filename):
            state = []
        else:
            with open(filename, "r") as f:
                state = json.load(f)
        if index >= len(state):
            state += [0] * (index - len(state) + 1)
        state[index] = value
        with open(filename, "w") as f2:
            json.dump(state, f2)
            print("update", state)
        return {"success": True, **data}
    return None
