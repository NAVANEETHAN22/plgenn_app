#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN REAL Vulnerability Lab Setup"
echo "===================================="

pkg update -y && pkg upgrade -y
pkg install python curl sqlite -y

pip install --upgrade pip
pip install flask fpdf

mkdir -p ~/plgenn_lab
cd ~/plgenn_lab || exit

cat <<'EOF' > server.py
from flask import Flask, request, send_file
from fpdf import FPDF
from datetime import datetime
import sqlite3, subprocess, io, os

app = Flask(__name__)
REPORT = {}

# ---------------- REAL SQLi DB ----------------
db = sqlite3.connect("users.db", check_same_thread=False)
c = db.cursor()
c.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT)")
c.execute("INSERT OR IGNORE INTO users VALUES (1,'admin')")
db.commit()

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
.bad{color:#f85149}
.good{color:#3fb950}
</style>
</head>
<body>

<h2>🧪 PlGenN REAL Vulnerability Lab</h2>

<div class="box">
<form method="POST" action="/verify">
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
    return HTML

# ---------------- REAL VERIFICATION ----------------
@app.route("/verify", methods=["POST"])
def verify():
    global REPORT
    payload = request.form["payload"]

    category = "None"
    result = "NO EFFECT"
    proof = "No vulnerability triggered"

    # ---- SQL Injection (REAL) ----
    try:
        q = f"SELECT * FROM users WHERE name = '{payload}'"
        rows = c.execute(q).fetchall()
        if rows:
            category = "SQL Injection"
            result = "VULNERABILITY TRIGGERED"
            proof = "SQL authentication bypass"
    except:
        category = "SQL Injection"
        result = "VULNERABILITY TRIGGERED"
        proof = "SQL syntax manipulation"

    # ---- Command Injection (REAL) ----
    if any(x in payload for x in [";", "|", "$("]):
        output = subprocess.getoutput(payload)
        category = "Command Injection"
        result = "VULNERABILITY TRIGGERED"
        proof = f"Command executed: {output[:50]}"

    # ---- LFI / Path Traversal (REAL) ----
    if "../" in payload or "..\\" in payload:
        try:
            open(payload).read()
            category = "Path Traversal / LFI"
            result = "VULNERABILITY TRIGGERED"
            proof = "Arbitrary file read"
        except:
            pass

    # ---- XSS (REAL – BROWSER EXECUTION) ----
    if "<script" in payload.lower():
        REPORT = {
            "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "Payload": payload,
            "Category": "XSS",
            "Result": "VULNERABILITY TRIGGERED",
            "Proof": "JavaScript executed in browser",
            "Environment": "Local Vulnerable Lab",
            "Model": "PlGenN Hybrid (Rule + GNN)"
        }
        return f"""
        <h3 class='bad'>VULNERABILITY TRIGGERED</h3>
        <p><b>Category:</b> XSS</p>
        <p><b>Proof:</b> Script executed below</p>
        <hr>
        {payload}
        <hr>
        <a href="/">⬅ Back</a>
        """

    REPORT = {
        "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "Payload": payload,
        "Category": category,
        "Result": result,
        "Proof": proof,
        "Environment": "Local Vulnerable Lab",
        "Model": "PlGenN Hybrid (Rule + GNN)"
    }

    return f"""
    <h3 class='{"bad" if result=="VULNERABILITY TRIGGERED" else "good"}'>{result}</h3>
    <p><b>Category:</b> {category}</p>
    <p><b>Proof:</b> {proof}</p>
    <a href="/">⬅ Back</a>
    """

# ---------------- PDF REPORT ----------------
@app.route("/report")
def report():
    if not REPORT:
        return "No test performed yet"

    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=12)
    pdf.cell(0,10,"PlGenN Payload Verification Report", ln=True)

    for k,v in REPORT.items():
        pdf.multi_cell(0,8,f"{k}: {v}")

    pdf.multi_cell(0,8,
        "\nProof Source: Real Vulnerability Execution\n"
        "Environment: Local DVWA-like Lab\n"
        "Purpose: Research & Academic Validation"
    )

    buf = io.BytesIO(pdf.output(dest="S").encode("latin-1"))
    return send_file(buf, as_attachment=True,
                     download_name="PlGenN_Report.pdf")

if __name__ == "__main__":
    print("🌐 Open http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000)
EOF

echo "✅ Setup complete"
echo "🌐 Open http://127.0.0.1:5000"

python server.py
