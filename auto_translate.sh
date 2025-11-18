#!/bin/bash
set -e

INPUT_FILE="$1"
BASENAME="${INPUT_FILE%.*}"
ENGLISH_SRT="${BASENAME}.srt"
WORD_JSON="${BASENAME}.json"
WORD_SRT="${BASENAME}_words.srt"
JA_SRT="${BASENAME}_ja.srt"
OUTPUT_XML="${BASENAME}_ja.fcpxml"

echo "🎬 Processing: $INPUT_FILE"


# ----------------------------------------------------------------------
# 0️⃣ Whisperで「英語SRT」＋「単語タイムコードJSON」生成
# ----------------------------------------------------------------------
if [ ! -f "$ENGLISH_SRT" ] || [ ! -f "$WORD_JSON" ]; then
  echo "🎧 Generating English subtitles + word timestamps with Whisper..."
  whisper "$INPUT_FILE" \
    --model medium \
    --language en \
    --word_timestamps True \
    --output_format "srt,json" \
    --output_dir .
else
  echo "✅ Found existing subtitle files."
fi


# ----------------------------------------------------------------------
# 0.5️⃣ JSON → word-level SRT (_words.srt) 自動生成
# ----------------------------------------------------------------------
if [ ! -f "$WORD_SRT" ]; then
  echo "🧠 Creating word-level SRT from Whisper JSON..."

  python3 - <<PYCODE
import json, os

json_file = "${WORD_JSON}"
out_file = "${WORD_SRT}"

def sec_to_srt_time(sec):
    millis = int(sec * 1000)
    h = millis // 3600000
    m = (millis % 3600000) // 60000
    s = (millis % 60000) // 1000
    ms = millis % 1000
    return f"{h:02}:{m:02}:{s:02},{ms:03}"

data = json.load(open(json_file))

lines = []
count = 1

for seg in data.get("segments", []):
    for w in seg.get("words", []):
        start = sec_to_srt_time(w["start"])
        end = sec_to_srt_time(w["end"])
        word = w["word"].strip()
        if not word:
            continue
        lines.append(f"{count}\n{start} --> {end}\n{word}\n")
        count += 1

with open(out_file, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print("✅ Word-level SRT created:", out_file)
PYCODE

else
  echo "⏩ Found existing word-level SRT: $WORD_SRT"
fi



# ----------------------------------------------------------------------
# 1️⃣ SRT翻訳（全文一括）
# ----------------------------------------------------------------------
if [ -f "$JA_SRT" ]; then
  echo "⏩ Found existing Japanese SRT, skipping translation."
else
  echo "🌏 Translating entire SRT (single API call)..."
  export ENGLISH_SRT JA_SRT
  python3 - <<'PYCODE'
import os, openai

openai.api_key = os.getenv("OPENAI_API_KEY")
src = os.environ["ENGLISH_SRT"]
dst = os.environ["JA_SRT"]

with open(src, encoding="utf-8") as f:
    srt_text = f.read().strip()

prompt = f"""
You are a professional Japanese subtitle translator for YouTube.

Translate the following entire SRT file into smooth, natural Japanese that sounds like casual spoken dialogue — easy to read and friendly for Japanese viewers.

⚠️ Strict rules:
1. Keep all block numbers and timecodes 100% unchanged.
2. Do not merge, split, or reorder blocks.
3. Translate only text lines.
4. Output must be a valid SRT file.
5. Use natural conversational Japanese.
6. For filler or reactions (“uh”, “wow”), keep short.

Translate this SRT:

{srt_text}
"""

print("🈶 Sending full SRT to GPT-5 ...", flush=True)

res = openai.ChatCompletion.create(
    model="gpt-5",
    messages=[{"role": "user", "content": prompt}],
)

translated = res.choices[0].message.content.strip()

with open(dst, "w", encoding="utf-8") as f:
    f.write(translated)

print("✅ Translation complete:", dst)
PYCODE
fi



# ----------------------------------------------------------------------
# 2️⃣ FCPXML生成 (日本語SRT → XML)
# ----------------------------------------------------------------------
echo "🧩 Generating Final Cut XML..."

# 💥 ここで必ず再セット（これが重要）
JA_SRT="${BASENAME}_ja.srt"
OUTPUT_XML="${BASENAME}_ja.fcpxml"

if [ ! -f "$JA_SRT" ]; then
  echo "❌ ERROR: Japanese SRT not found: $JA_SRT"
  exit 1
fi

export JA_SRT
export OUTPUT_XML

python3 - <<'PYCODE'
import re, os, uuid
from datetime import datetime

srt_path = os.environ["JA_SRT"]
xml_path = os.environ["OUTPUT_XML"]

basename = os.path.basename(srt_path).replace(".srt","")

def to_frame_time(sec: float) -> str:
    return f"{int(sec * 2500)}/2500s"

def parse_srt(path):
    entries = []
    with open(path, encoding="utf-8") as f:
        raw = f.read().strip().split("\n\n")

    for block in raw:
        lines = block.split("\n")
        if len(lines) < 3:
            continue

        time = lines[1]
        text = " ".join(lines[2:])

        start, end = time.split(" --> ")

        def to_sec(t):
            h,m,s = t.split(":")
            s,ms = s.split(",")
            return int(h)*3600 + int(m)*60 + int(s) + int(ms)/1000

        s = to_sec(start)
        e = to_sec(end)
        entries.append((s, e, e - s, text))

    return entries

entries = parse_srt(srt_path)
if not entries:
    raise RuntimeError("SRT parsed empty")

uid_event = uuid.uuid4().hex.upper()
uid_project = uuid.uuid4().hex.upper()
moddate = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S +0000")

# ==== duration は SRT の最終 end 秒 ====
total_duration_sec = max(e for _,e,_,_ in entries)
total_duration_frame = to_frame_time(total_duration_sec)

xml = []
xml.append('<?xml version="1.0" encoding="UTF-8"?>')
xml.append('<!DOCTYPE fcpxml>')
xml.append('<fcpxml version="1.9">')

xml.append('  <resources>')
xml.append('    <format id="r1" name="FFVideoFormat1080p25" frameDuration="1/25s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>')
xml.append('    <effect id="r2" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>')
xml.append('  </resources>')

xml.append('  <library>')
xml.append(f'    <event name="{basename}" uid="{uid_event}">')
xml.append(f'      <project name="{basename}" uid="{uid_project}" modDate="{moddate}">')
xml.append(f'        <sequence format="r1" duration="{total_duration_frame}" tcStart="0/25s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">')
xml.append('          <spine>')
xml.append(f'            <gap name="Gap" offset="0s" start="0s" duration="{total_duration_frame}">')

# ==== 字幕本体 ====
for i, (start_s, end_s, dur_s, text) in enumerate(entries, start=1):
    start = to_frame_time(start_s)
    dur   = to_frame_time(dur_s)

    xml.append(f'              <title ref="r2" lane="1" name="{text} - Basic Title" offset="{start}" start="{start}" duration="{dur}">')
    xml.append('                <param name="Flatten" key="9999/999166631/999166633/2/351" value="1"/>')

    # Final Cut が生成する2つの Alignment param
    xml.append('                <param name="Alignment" key="9999/999166631/999166633/2/354/3142713059/401" value="1 (Center)"/>')
    xml.append('                <param name="Alignment" key="9999/999166631/999166633/2/354/999169573/401" value="1 (Center)"/>')

    xml.append('                <text>')
    xml.append(f'                  <text-style ref="ts{i}">{text}</text-style>')
    xml.append('                </text>')
    xml.append(f'                <text-style-def id="ts{i}">')
    xml.append('                  <text-style font="Helvetica" fontSize="60" fontColor="1 1 1 1" alignment="center" fontFace="Regular"/>')
    xml.append('                </text-style-def>')
    xml.append('              </title>')

xml.append('            </gap>')
xml.append('          </spine>')
xml.append('        </sequence>')
xml.append('      </project>')

# ==== smart-collection (1つ目XMLに合わせた) ====
xml.append('      <smart-collection name="Projects" match="all"><match-clip rule="is" type="project"/></smart-collection>')
xml.append('      <smart-collection name="All Video" match="any"><match-media rule="is" type="videoOnly"/><match-media rule="is" type="videoWithAudio"/></smart-collection>')
xml.append('      <smart-collection name="Audio Only" match="all"><match-media rule="is" type="audioOnly"/></smart-collection>')
xml.append('      <smart-collection name="Stills" match="all"><match-media rule="is" type="stills"/></smart-collection>')
xml.append('      <smart-collection name="Favorites" match="all"><match-ratings value="favorites"/></smart-collection>')

xml.append('    </event>')
xml.append('  </library>')
xml.append('</fcpxml>')

with open(xml_path, "w", encoding="utf-8") as f:
    f.write("\n".join(xml))

print("✅ Generated:", xml_path)
PYCODE

echo "🎉 Done: $OUTPUT_XML"
