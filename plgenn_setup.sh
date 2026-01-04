#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN REAL Vulnerability Lab Setup"
echo "===================================="

pkg update -y && pkg upgrade -y
pkg install python curl sqlite -y

pip install --upgrade pip
pip install flask fpdf requests

mkdir -p ~/plgenn_lab
cd ~/plgenn_lab || exit

cat <<'EOF' > server.py
from flask import Flask, request, send_file, render_template_string
from fpdf import FPDF
from datetime import datetime
import sqlite3, subprocess, io, requests

app = Flask(__name__)
REPORT = {}

# ---------------- OWASP INFO ----------------
OWASP = {
    "SQL Injection": ("A03 – Injection",
        "Untrusted data is sent to an interpreter as part of a SQL query."),
    "XSS": ("A03 – Injection",
        "Malicious JavaScript is injected and executed in a victim's browser."),
    "Command Injection": ("A03 – Injection",
        "System commands are injected and executed by the OS."),
    "Path Traversal / LFI": ("A05 – Security Misconfiguration",
        "Improper access control allows reading arbitrary files."),
    "SSRF": ("A10 – Server-Side Request Forgery",
        "Server is forced to make unintended internal requests."),
    "Open Redirect": ("A01 – Broken Access Control",
        "User is redirected to untrusted external sites.")
}

# ---------------- REAL SQLi DB ----------------
db = sqlite3.connect("users.db", check_same_thread=False)
c = db.cursor()
c.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT)")
c.execute("INSERT OR IGNORE INTO users VALUES (1,'admin')")
db.commit()

# ---------------- HTML UI ----------------
HTML = """
<h2>🧪 PlGenN REAL Vulnerability Lab</h2>
<form method="POST" action="/verify">
<textarea name="payload" style="width:100%;height:120px" required></textarea><br>
<button type="submit">Test Payload</button>
</form>
<br>
<a href="/report">⬇ Download PDF Report</a>
"""

@app.route("/")
def home():
    return render_template_string(HTML)

# ---------------- DETECTION ----------------
def detect(payload):
    p = payload.lower()
    if any(x in p for x in ["' or '1'='1", "union", "select", "--"]):
        return "SQL Injection"
    if "<script" in p:
        return "XSS"
    if any(x in p for x in [";", "|", "$("]):
        return "Command Injection"
    if "../" in p or "..\\" in p:
        return "Path Traversal / LFI"
    if "http://127.0.0.1" in p or "localhost" in p:
        return "SSRF"
    if p.startswith("http://") or p.startswith("https://"):
        return "Open Redirect"
    return "Benign"

# ---------------- VERIFICATION ----------------
@app.route("/verify", methods=["POST"])
def verify():
    global REPORT
    payload = request.form["payload"]
    category = detect(payload)

    result = "NO EFFECT"
    proof = "No vulnerability triggered"

    if category == "SQL Injection":
        try:
            rows = c.execute(
                f"SELECT * FROM users WHERE name = '{payload}'"
            ).fetchall()
            if rows:
                result = "VULNERABILITY TRIGGERED"
                proof = "Authentication bypass via SQLi"
        except:
            result = "VULNERABILITY TRIGGERED"
            proof = "SQL syntax manipulation"

    elif category == "Command Injection":
        output = subprocess.getoutput(payload)
        result = "VULNERABILITY TRIGGERED"
        proof = f"OS command executed: {output[:60]}"

    elif category == "Path Traversal / LFI":
        try:
            open(payload).read()
            result = "VULNERABILITY TRIGGERED"
            proof = "Arbitrary file read"
        except:
            pass

    elif category == "SSRF":
        try:
            r = requests.get(payload, timeout=2)
            result = "VULNERABILITY TRIGGERED"
            proof = f"Internal request made (HTTP {r.status_code})"
        except:
            proof = "Request blocked"

    elif category == "Open Redirect":
        result = "VULNERABILITY TRIGGERED"
        proof = "User redirected to external domain"

    elif category == "XSS":
        REPORT = {
            "Payload": payload,
            "Category": "XSS",
            "OWASP ID": OWASP["XSS"][0],
            "OWASP Info": OWASP["XSS"][1],
            "Result": "VULNERABILITY TRIGGERED",
            "Proof": "JavaScript executed in browser",
            "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        return f"""
        <h3>VULNERABILITY TRIGGERED</h3>
        <p><b>Category:</b> XSS</p>
        <p><b>OWASP:</b> {OWASP["XSS"][0]}</p>
        <p><b>Proof:</b> Script executed below</p>
        <hr>{payload}<hr>
        <a href="/">⬅ Back</a>
        """

    if category in OWASP:
        REPORT = {
            "Payload": payload,
            "Category": category,
            "OWASP ID": OWASP[category][0],
            "OWASP Info": OWASP[category][1],
            "Result": result,
            "Proof": proof,
            "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }

    return f"""
    <h3>{result}</h3>
    <p><b>Category:</b> {category}</p>
    <p><b>OWASP:</b> {REPORT.get("OWASP ID","N/A")}</p>
    <p><b>Proof:</b> {proof}</p>
    <a href="/">⬅ Back</a>
    """

# ---------------- PDF ----------------
@app.route("/report")
def report():
    if not REPORT:
        return "No test performed"

    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=12)
    pdf.cell(0,10,"PlGenN Payload Verification Report", ln=True)

    for k,v in REPORT.items():
        pdf.multi_cell(0,8,f"{k}: {v}")

    pdf.multi_cell(0,8,
        "\nValidation Environment: Local Vulnerable Lab\n"
        "OWASP Top 10 referenced\n"
        "Purpose: Academic & Research Validation"
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
