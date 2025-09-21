# app/app.py
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({"message": "Hello from Flask on EKS CI/CD tutorial!"})

@app.route("/health")
def health():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    # for local dev only; in production container we will use gunicorn
    app.run(host="0.0.0.0", port=5000, debug=True)
