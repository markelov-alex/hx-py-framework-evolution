import json

from flask import Flask, send_file, request

from v5.sockets import Parser, MyController

# Use classes from socket server v5 as common solution
# (Unification of http and socket servers logic complete)
print("http v8")


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
        self.storage = None  # should be HTTPRepository(), accessing DB
        self.default_controller = default_controller
        self.controller_by_key = controller_by_key or {}

    def handle_request(self, key, request):
        # Parse
        command, _ = self.parser.parse(request)
        # Handle
        controller = self.controller_by_key.get(key, self.default_controller)
        index, result = "xxx", []
        controller.handle_command(self.storage, index, command, result)
        # Get response
        response = []
        for indexes, commands in result:
            if "xxx" in indexes:
                response.extend(commands)
        # Response
        return self.parser.serialize(response[0] if len(response) == 1 else response)

    # def handle_request(self, key, request):
    #     commands, _ = self.parser.parse(request)
    #     result = []
    #     for command in commands:
    #         controller = self.controller_by_key.get(key, self.default_controller)
    #         result.extend(controller.handle_command(command))
    #     return self.parser.serialize(result)


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


application = FlaskApplication(FlaskParser(), MyController())
