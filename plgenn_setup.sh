#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN Local Testing Setup Started"
echo "==================================="

# Update Termux safely
pkg update -y && pkg upgrade -y

# Install dependencies
pkg install python curl -y

# Python packages
pip install --upgrade pip
pip install flask

# Create workspace
mkdir -p ~/plgenn_testing
cd ~/plgenn_testing || exit

# -------------------------------
# Flask server with WEB UI
# -------------------------------
cat <<'EOF' > server.py
from flask import Flask, request, jsonify, render_template_string

app = Flask(__name__)

HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>PlGenN Payload Testing</title>
    <style>
        body { font-family: Arial; background:#111; color:#eee; padding:20px }
        textarea { width:100%; height:120px; font-size:16px }
        button { padding:10px 20px; font-size:16px; margin-top:10px }
        .result { margin-top:20px; font-size:18px; font-weight:bold }
    </style>
</head>
<body>
    <h2>🧪 PlGenN Local Payload Testing</h2>
    <p>Paste your generated payload below:</p>

    <textarea id="payload"></textarea><br>
    <button onclick="testPayload()">Test Payload</button>

    <div class="result" id="result"></div>

<script>
function testPayload() {
    const payload = document.getElementById("payload").value;

    fetch("/test", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ payload })
    })
    .then(res => res.json())
    .then(data => {
        document.getElementById("result").innerText =
            "Result: " + data.result;
    });
}
</script>
</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML_PAGE)

@app.route("/test", methods=["POST"])
def test_payload():
    data = request.get_json(force=True)
    payload = data.get("payload", "")

    dangerous_patterns = [
        "'", "\"", "--", "/*", "*/",
        " or ", " and ", "union", "select",
        "<script", "../", ";", "|", "$("
    ]

    if any(p in payload.lower() for p in dangerous_patterns):
        result = "⚠️ Potentially Malicious"
    else:
        result = "✅ Likely Safe"

    return jsonify({
        "payload": payload,
        "result": result
    })

if __name__ == "__main__":
    print("🌐 Open browser at: http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000)
EOF

echo ""
echo "✅ Setup Complete"
echo "🌐 Open browser: http://127.0.0.1:5000"
echo ""

# Auto-start server
python server.py
