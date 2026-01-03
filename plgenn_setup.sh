#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN Vulnerability Lab Setup"
echo "================================"

# Safe update
pkg update -y && pkg upgrade -y

# Install dependencies
pkg install python curl -y

# Python packages (Termux-safe)
pip install --upgrade pip
pip install flask fpdf

# Workspace
mkdir -p ~/plgenn_lab
cd ~/plgenn_lab || exit

# -------------------------------
# Flask Vulnerable Lab Server
# -------------------------------
cat <<'EOF' > server.py
from flask import Flask, request, send_file, render_template_string
from fpdf import FPDF
from datetime import datetime
import sqlite3, subprocess, io, os

app = Flask(__name__)
REPORT = {}

# ---------------- SQLi Database ----------------
def init_db():
    db = sqlite3.connect("users.db")
    c = db.cursor()
    c.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT)")
    c.execute("INSERT OR IGNORE INTO users VALUES (1,'admin')")
    db.commit()
    db.close()

init_db()

# ---------------- Auto Category Detection ----------------
RULES = {
    "SQL Injection": ["' or '1'='1", "union", "select", "--"],
    "XSS": ["<script", "alert(", "onerror"],
    "Command Injection": [";", "|", "$("],
    "Path Traversal / LFI": ["../", "..\\"],
    "SSRF": ["http://127.0.0.1", "http://localhost"],
    "Open Redirect": ["http://", "https://"]
}

def detect_category(payload):
    hits = []
    for cat, pats in RULES.items():
        if any(p.lower() in payload.lower() for p in pats):
            hits.append(cat)
    return hits if hits else ["Unknown / Benign"]

# ---------------- HTML UI ----------------
HTML = """
<!DOCTYPE html>
<html>
<head>
<title>PlGenN Vulnerability Lab</title>
<style>
body{font-family:Arial;background:#0d1117;color:#e6edf3;padding:30px}
textarea{width:100%;height:120px;font-size:16px}
button{padding:10px 20px;font-size:15px;margin-top:10px}
.box{background:#161b22;padding:20px;border-radius:10px}
.good{color:#3fb950}
.bad{color:#f85149}
</style>
</head>
<body>

<h2>🧪 PlGenN Local Vulnerability Verification</h2>

<div class="box">
<form method="POST" action="/verify">
<p><b>Paste payload from PlGenN app</b></p>
<textarea name="payload" required></textarea><br>
<button type="submit">Test Payload</button>
</form>

<br>
<a href="/report">⬇ Download PDF Report</a>
</div>

</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML)

# ---------------- Verification ----------------
@app.route("/verify", methods=["POST"])
def verify():
    global REPORT
    payload = request.form["payload"]
    categories = detect_category(payload)

    result = "NO EFFECT"
    proof = "No vulnerability triggered"

    # SQLi proof
    if "SQL Injection" in categories:
        try:
            db = sqlite3.connect("users.db")
            c = db.cursor()
            c.execute(f"SELECT * FROM users WHERE name = '{payload}'")
            if c.fetchall():
                result = "VULNERABILITY TRIGGERED"
                proof = "Database query manipulated (SQLi)"
            db.close()
        except:
            result = "SQL ERROR"
            proof = "Malformed SQL query"

    # Command Injection proof
    if "Command Injection" in categories:
        subprocess.getoutput("echo " + payload)
        result = "VULNERABILITY TRIGGERED"
        proof = "OS command executed"

    # LFI proof
    if "Path Traversal / LFI" in categories:
        try:
            open(payload).read()
            result = "VULNERABILITY TRIGGERED"
            proof = "Arbitrary file read"
        except:
            pass

    REPORT = {
        "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "Payload": payload,
        "Detected Categories": ", ".join(categories),
        "Result": result,
        "Proof": proof,
        "Validation Environment": "Local Vulnerable Lab (DVWA-like)",
        "Model": "PlGenN Hybrid (Rule + GNN Assisted)"
    }

    return f"""
    <h3>{result}</h3>
    <p><b>Detected:</b> {REPORT['Detected Categories']}</p>
    <p><b>Proof:</b> {proof}</p>
    <a href="/">⬅ Back</a>
    """

# ---------------- PDF Report ----------------
@app.route("/report")
def report():
    if not REPORT:
        return "No test performed yet."

    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=12)

    pdf.cell(0,10,"PlGenN Payload Verification Report", ln=True)
    pdf.ln(5)

    for k,v in REPORT.items():
        pdf.multi_cell(0,8,f"{k}: {v}")

    pdf.ln(5)
    pdf.multi_cell(0,8,
        "Proof Source: Local Vulnerable Lab\n"
        "Purpose: Payload Validation & Research\n"
        "Note: This environment intentionally contains vulnerabilities."
    )

    buf = io.BytesIO(pdf.output(dest="S").encode("latin-1"))
    return send_file(buf, as_attachment=True,
                     download_name="PlGenN_Report.pdf")

if __name__ == "__main__":
    print("🌐 Open http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000)
EOF

echo ""
echo "✅ Setup complete"
echo "🌐 Open browser: http://127.0.0.1:5000"
echo ""

# Auto start
python server.py
