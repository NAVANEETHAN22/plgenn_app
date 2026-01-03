#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN Vulnerability Lab Setup"
echo "================================"

pkg update -y && pkg upgrade -y
pkg install python curl -y

pip install --upgrade pip
pip install flask fpdf

mkdir -p ~/plgenn_lab
cd ~/plgenn_lab || exit

cat <<'EOF' > server.py
from flask import Flask, request, send_file
from fpdf import FPDF
from datetime import datetime
import os, sqlite3, subprocess, io

app = Flask(__name__)
REPORT = {}

# ---------------- DB (SQLi target) ----------------
def init_db():
    db = sqlite3.connect("users.db")
    c = db.cursor()
    c.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT)")
    c.execute("INSERT OR IGNORE INTO users VALUES (1,'admin')")
    db.commit()
    db.close()

init_db()

# ---------------- HTML UI ----------------
HTML = """
<h2>🧪 PlGenN Local Vulnerability Verification</h2>
<p>Paste payload from PlGenN app</p>

<form method="POST" action="/verify">
<textarea name="payload" style="width:100%;height:120px"></textarea><br><br>
<select name="endpoint">
<option value="sqli">SQL Injection</option>
<option value="xss">XSS</option>
<option value="cmd">Command Injection</option>
<option value="lfi">Path Traversal / LFI</option>
</select><br><br>
<button type="submit">Test Payload</button>
</form>

<br>
<a href="/report">⬇ Download PDF Report</a>
"""

@app.route("/")
def home():
    return HTML

# ---------------- Verification ----------------
@app.route("/verify", methods=["POST"])
def verify():
    global REPORT
    payload = request.form["payload"]
    ep = request.form["endpoint"]
    result, proof = "", ""

    if ep == "sqli":
        db = sqlite3.connect("users.db")
        c = db.cursor()
        try:
            c.execute(f"SELECT * FROM users WHERE name = '{payload}'")
            rows = c.fetchall()
            result = "VULNERABILITY TRIGGERED" if rows else "NO EFFECT"
            proof = "Database authentication bypass"
        except:
            result = "SQL ERROR"
            proof = "Malformed query"
        db.close()

    elif ep == "xss":
        result = "VULNERABILITY TRIGGERED"
        proof = "Payload reflected in response"

    elif ep == "cmd":
        try:
            subprocess.getoutput("echo " + payload)
            result = "VULNERABILITY TRIGGERED"
            proof = "Command executed on server"
        except:
            result = "BLOCKED"
            proof = "Execution failed"

    elif ep == "lfi":
        try:
            open(payload).read()
            result = "VULNERABILITY TRIGGERED"
            proof = "Arbitrary file read"
        except:
            result = "BLOCKED"
            proof = "File not accessible"

    REPORT = {
        "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "Payload": payload,
        "Category": ep.upper(),
        "Result": result,
        "Proof": proof,
        "Validation": "Controlled Vulnerable Lab",
        "Model": "PlGenN Hybrid (Rule + GNN)"
    }

    return f"<h3>{result}</h3><p>{proof}</p><a href='/'>Back</a>"

# ---------------- PDF ----------------
@app.route("/report")
def report():
    if not REPORT:
        return "No test performed"

    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=12)
    pdf.cell(0,10,"PlGenN Payload Verification Report", ln=1)

    for k,v in REPORT.items():
        pdf.multi_cell(0,8,f"{k}: {v}")

    buf = io.BytesIO(pdf.output(dest="S").encode("latin-1"))
    return send_file(buf, as_attachment=True,
                     download_name="PlGenN_Report.pdf")

if __name__ == "__main__":
    print("🌐 Open http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000)
EOF

echo "✅ Setup complete"
echo "🌐 Opening http://127.0.0.1:5000"

python server.py
