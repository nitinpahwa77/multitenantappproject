from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_tenant2():
    return "Welcome to Tenant 2's Application!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
