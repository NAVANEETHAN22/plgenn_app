#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN Local Testing Setup Started"
echo "==================================="

# Update Termux
pkg update -y
pkg upgrade -y

# Install dependencies
pkg install python git curl -y

# Install Python libraries
pip install --upgrade pip
pip install flask requests

# Create workspace
mkdir -p ~/plgenn_testing
cd ~/plgenn_testing || exit

# Create Flask server
cat <<'EOF' > server.py
from flask import Flask, request, jsonify

app = Flask(__name__)

# ✅ Root route (browser check)
@app.route("/")
def home():
    return {
        "status": "PlGenN Local Testing Server Running",
        "usage": "POST payloads to /test"
    }

# ✅ Payload testing API
@app.route("/test", methods=["POST"])
def test_payload():
    data = request.get_json(force=True)
    payload = data.get("payload", "")

    dangerous_patterns = [
        "'", "\"", "--", "/*", "*/",
        " or ", " and ", "union", "select",
        "<script", "../", ";", "|", "$("
    ]

    if any(p.lower() in payload.lower() for p in dangerous_patterns):
        result = "⚠️ Potentially Malicious"
    else:
        result = "✅ Likely Safe"

    return jsonify({
        "payload": payload,
        "result": result
    })

app.run(host="0.0.0.0", port=5000)
EOF

echo ""
echo "✅ Setup Complete!"
echo "🚀 Starting PlGenN Local Testing Server..."
echo ""

# Auto-start server
python server.py
