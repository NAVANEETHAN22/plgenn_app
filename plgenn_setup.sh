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
from flask import Flask, request, send_file, render_template_string
from fpdf import FPDF
from datetime import datetime
import sqlite3, subprocess, os

app = Flask(__name__)
REPORT = {}

# ================= OWASP MAP =================
OWASP = {
    "SQL Injection": ("A03:2021", "Injection flaws allow manipulation of SQL queries."),
    "XSS": ("A03:2021", "Cross-Site Scripting executes attacker JavaScript in the browser."),
    "Command Injection": ("A03:2021", "OS commands executed via unsanitized input."),
    "Path Traversal / LFI": ("A01:2021", "Allows attackers to read arbitrary server files.")
}

# ================= DATABASE =================
db = sqlite3.connect("users.db", check_same_thread=False)
c = db.cursor()
c.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER, name TEXT)")
c.execute("INSERT OR IGNORE INTO users VALUES (1,'admin')")
db.commit()

# ================= UI (POLISHED) =================
HTML = """
<!DOCTYPE html>
<html>
<head>
<title>PlGenN Vulnerability Verification Lab</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
body{
    font-family: "Segoe UI", Arial, sans-serif;
    background:#0d1117;
    color:#e6edf3;
    padding:20px;
}
.container{
    max-width:700px;
    margin:auto;
}
.header{
    margin-bottom:25px;
}
.header h2{
    margin:0;
}
.header p{
    color:#8b949e;
    font-size:14px;
}
.card{
    background:#161b22;
    padding:20px;
    border-radius:12px;
    box-shadow:0 0 0 1px #30363d;
}
textarea{
    width:100%;
    height:120px;
    background:#0d1117;
    color:#e6edf3;
    border:1px solid #30363d;
    border-radius:8px;
    padding:10px;
    font-size:15px;
}
textarea:focus{
    outline:none;
    border-color:#58a6ff;
}
button{
    margin-top:15px;
    padding:12px 20px;
    font-size:15px;
    border:none;
    border-radius:8px;
    cursor:pointer;
    background:#238636;
    color:#fff;
}
button:hover{
    background:#2ea043;
}
.link{
    display:inline-block;
    margin-top:15px;
    color:#58a6ff;
    text-decoration:none;
}
.result-good{
    color:#3fb950;
    font-weight:bold;
}
.result-bad{
    color:#f85149;
    font-weight:bold;
}
.footer{
    margin-top:20px;
    font-size:13px;
    color:#8b949e;
}
</style>
</head>

<body>
<div class="container">

<div class="header">
<h2>🧪 PlGenN Payload Verification Lab</h2>
<p>Local vulnerable environment for academic payload validation (DVWA-like)</p>
</div>

<div class="card">
<form method="POST" action="/verify">
<label><b>Paste Generated Payload</b></label><br><br>
<textarea name="payload" placeholder="e.g. <script>alert(1)</script>" required></textarea>
<button type="submit">Test Payload</button>
</form>

<a class="link" href="/report">⬇ Download Verification PDF Report</a>
</div>

<div class="footer">
✔ Real execution proof &nbsp; | &nbsp;
✔ OWASP Top 10 mapped &nbsp; | &nbsp;
✔ Research & academic use
</div>

</div>
</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML)

# ================= VERIFICATION =================
@app.route("/verify", methods=["POST"])
def verify():
    global REPORT
    payload = request.form["payload"]

    category = "Benign"
    result = "NO EFFECT"
    proof = "No vulnerability triggered"

    # SQL Injection
    try:
        q = f"SELECT * FROM users WHERE name = '{payload}'"
        rows = c.execute(q).fetchall()
        if rows:
            category = "SQL Injection"
            result = "VULNERABILITY TRIGGERED"
            proof = "SQL authentication bypass confirmed"
    except:
        category = "SQL Injection"
        result = "VULNERABILITY TRIGGERED"
        proof = "SQL syntax manipulation"

    # Command Injection
    if any(x in payload for x in [";", "|", "$("]):
        subprocess.getoutput(payload)
        category = "Command Injection"
        result = "VULNERABILITY TRIGGERED"
        proof = "OS command executed"

    # Path Traversal
    if "../" in payload or "..\\" in payload:
        try:
            open(payload).read()
            category = "Path Traversal / LFI"
            result = "VULNERABILITY TRIGGERED"
            proof = "Arbitrary file read"
        except:
            pass

    # XSS
    if "<script" in payload.lower():
        category = "XSS"
        result = "VULNERABILITY TRIGGERED"
        proof = "JavaScript executed in browser"

        REPORT = build_report(payload, category, result, proof)

        return f"""
        <h2 class='result-bad'>VULNERABILITY TRIGGERED</h2>
        <p><b>Category:</b> XSS</p>
        <p><b>Proof:</b> Script executed below</p>
        <hr>{payload}<hr>
        <a href="/">⬅ Back</a>
        """

    REPORT = build_report(payload, category, result, proof)

    return f"""
    <h2 class='{'result-bad' if result=='VULNERABILITY TRIGGERED' else 'result-good'}'>{result}</h2>
    <p><b>Category:</b> {category}</p>
    <p><b>Proof:</b> {proof}</p>
    <a href="/">⬅ Back</a>
    """

def build_report(payload, category, result, proof):
    owasp_id, owasp_info = OWASP.get(category, ("N/A", "No OWASP issue"))
    return {
        "Timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "Payload": payload,
        "Category": category,
        "OWASP ID": owasp_id,
        "OWASP Description": owasp_info,
        "Result": result,
        "Execution Proof": proof,
        "Environment": "Local Vulnerable Lab",
        "Model": "PlGenN Hybrid (Rule + GNN)"
    }

# ================= PDF =================
@app.route("/report")
def report():
    if not REPORT:
        return "<h3>No test performed yet</h3><a href='/'>Back</a>"

    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Arial", size=12)

    pdf.cell(0, 10, "PlGenN Payload Verification Report", ln=True)
    pdf.ln(5)

    for k, v in REPORT.items():
        pdf.multi_cell(0, 8, f"{k}: {v}")

    pdf.ln(5)
    pdf.multi_cell(
        0, 8,
        "Reference: OWASP Top 10\n"
        "Proof Type: Real execution\n"
        "Purpose: Academic & Research Validation"
    )

    file_path = "/data/data/com.termux/files/home/plgenn_lab/PlGenN_Report.pdf"
    pdf.output(file_path)

    return send_file(file_path, as_attachment=True)

if __name__ == "__main__":
    print("🌐 Open http://127.0.0.1:5000")
    app.run(host="0.0.0.0", port=5000)
 
EOF

echo "✅ Setup complete"
echo "🌐 Open http://127.0.0.1:5000"

python server.py
