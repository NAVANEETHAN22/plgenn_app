#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN Local Testing Setup Started"

pkg update -y
pkg upgrade -y

pkg install python git curl -y

pip install flask requests

mkdir -p plgenn_testing
cd plgenn_testing

cat <<EOF > server.py
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/test', methods=['POST'])
def test_payload():
    payload = request.json.get("payload", "")
    result = "Potentially Malicious" if any(x in payload.lower() for x in ["select", "<script", "../", "||"]) else "Likely Safe"
    return jsonify({
        "payload": payload,
        "result": result
    })

app.run(host="0.0.0.0", port=5000)
EOF

echo "✅ Setup Complete"
echo "👉 Start server using: python server.py"
