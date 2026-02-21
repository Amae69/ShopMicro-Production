from flask import Flask, jsonify, request
import random
import os

app = Flask(__name__)

@app.get("/health")
@app.get("/health/live")
@app.get("/health/ready")
def health():
    return jsonify({"status": "ok", "service": "ml-service"})

@app.get("/recommendations/<int:user_id>")
def recommendations(user_id: int):
    catalog = ["keyboard", "monitor", "headset", "mouse", "webcam"]
    random.seed(user_id)
    picks = random.sample(catalog, 3)
    return jsonify({"user_id": user_id, "recommendations": picks})

@app.get("/metrics")
def metrics():
    # Minimal placeholder so scraping does not fail in starter mode
    return "shopmicro_ml_requests_total 1\n", 200, {"Content-Type": "text/plain; version=0.0.4"}

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 3002))
    app.run(host="0.0.0.0", port=port)
