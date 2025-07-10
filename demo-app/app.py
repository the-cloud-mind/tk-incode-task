import os

from flask import Flask, request, jsonify

app = Flask('hello')


@app.route("/")
def hello():
    return jsonify("This is custom app response")


@app.route("/healthy")
def healthy():
    return jsonify("App is healthy!")


@app.route("/ready")
def ready():
    return jsonify("App is ready!")


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=os.environ.get('PORT', 8080))