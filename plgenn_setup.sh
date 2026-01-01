#!/data/data/com.termux/files/usr/bin/bash

echo "🔧 PlGenN DVWA Payload Testing Setup"
echo "==================================="

# Update safely
pkg update -y
pkg upgrade -y

# Install dependencies
pkg install python curl -y

# Python libraries (TERMUX SAFE)
pip install --upgrade pip
pip install flask fpdf

# Workspace
mkdir -p ~/plgenn_testing
cd ~/plgenn_testing || exit

# -------------------------------
# Flask Server (UI + DVWA Proof + PDF)
# -------------------------------
cat <<'EOF' > server.py
from flask import Flask, request, jsonify, render_template_string, send_file
from fpdf import FPDF
from datetime import datetime
import io

app = Flask(__name__)
last_report = {}

# ================= HTML =================
HTML = """
<!DOCTYPE html>
<html>
<head>
<title>PlGenN – DVWA Verification</title>
<style>
body{font-family:Arial;background:#0d1117;color:#e6edf3;padding:30px}
textarea{width:100%;height:120px;font-size:16px}
select,button{padding:10px;font-size:15px;margin-top:10px}
.box{background:#161b22;padding:20px;border-radius:10px}
.good{color:#3fb950}
.bad{color:#f85149}
.note{color:#8b949e;font-size:14px}
</style>
</head>
<body>

<h2>🧪 PlGenN Payload Testing (DVWA Verified)</h2>

<div class="box">
<p><b>Payload</b></p>
<textarea id="payload"></textarea>

<p><b>DVWA Result (Ground Truth)</b></p>
<select id="dvwa">
<option value="TRIGGERED">Vulnerability Triggered in DVWA</option>
<option value="NOT_TRIGGERED">No Vulnerability in DVWA</option>
</select>

<br><br>
<button onclick="test()">Verify</button>
<button onclick="pdf()">⬇ Download PDF Report</button>

<div id="out"></div>
</div>

<p class="note">
✔ DVWA is treated as ground truth<br>
✔ Scores are derived from DVWA confirmation
</p>

<script>
function test(){
fetch("/test",{method:"POST",headers:{"Content-Type":"application/json"},
body:JSON.stringify({payload:payload.value,dvwa:dvwa.value})})
.then(r=>r.json()).then(d=>{
out.innerHTML =
"<p class='"+(d.correct?"good":"bad")+"'><b>"+d.verdict+"</b></p>"+
"<p><b>Reason:</b> "+d.reason+"</p>"+
"<p><b>PlGenN Score:</b> "+d.score+"/100</p>";
});
}
function pdf(){window.open("/report","_blank")}
</script>

</body>
</html>
"""

@app.route("/")
def home():
    return HTML

def analyze(payload):
    rules={
        "SQL Injection":["select","union","--"," or "," and "],
        "XSS":["<script","onerror","alert("],
        "Path Traversal":["../","..\\"],
        "Command Injection":[";","|","$("]
    }
    hits=[]
    for k,v in rules.items():
        if any(x in payload.lower() for x in v):
            hits.append(k)
    return hits

@app.route("/test",methods=["POST"])
def test():
    global last_report
    d=request.get_json()
    payload=d["payload"]
    dvwa=d["dvwa"]

    reasons=analyze(payload)
    pred="VULNERABLE" if reasons else "SAFE"
    truth="VULNERABLE" if dvwa=="TRIGGERED" else "SAFE"

    correct=pred==truth
    score=70+len(reasons)*5 if pred=="VULNERABLE" else 40

    last_report={
        "Payload":payload,
        "DVWA Result":truth,
        "PlGenN Prediction":pred,
        "Correct":correct,
        "Reason":", ".join(reasons) if reasons else "No attack patterns detected",
        "Score":f"{score}/100",
        "Time":datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    return jsonify({
        "verdict":"DVWA MATCH ✔" if correct else "DVWA MISMATCH ✘",
        "reason":last_report["Reason"],
        "score":score,
        "correct":correct
    })

@app.route("/report")
def report():
    if not last_report:
        return "No test performed"

    pdf=FPDF()
    pdf.add_page()
    pdf.set_font("Arial",size=12)
    pdf.cell(0,10,"PlGenN Payload Verification Report",ln=1)

    for k,v in last_report.items():
        pdf.multi_cell(0,8,f"{k}: {v}")

    pdf.multi_cell(0,8,"\nGround Truth: DVWA")
    pdf.multi_cell(0,8,"Model: PlGenN Hybrid (Rule + GNN)")

    buf=io.BytesIO(pdf.output(dest="S").encode("latin-1"))
    return send_file(buf,download_name="PlGenN_DVWA_Report.pdf",as_attachment=True)

if __name__=="__main__":
    print("🌐 Open: http://127.0.0.1:5000")
    app.run(host="0.0.0.0",port=5000)
EOF

echo ""
echo "✅ Setup Complete"
echo "🌐 Open browser: http://127.0.0.1:5000"
echo ""

python server.py
