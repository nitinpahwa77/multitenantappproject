from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_tenant1():
    return "Welcome to Tenant 1's Application!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)