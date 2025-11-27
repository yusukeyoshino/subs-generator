🎬 Auto Subtitle Pipeline (Whisper → Translation → FCPXML)

This script provides a fully automated pipeline for generating English subtitles, word-level timestamps, Japanese translations, and Final Cut Pro–ready FCPXML files from any audio or video input.

It is designed for YouTube creators, editors, and anyone who needs fast and accurate subtitle workflows with Whisper + GPT + Final Cut Pro.

🚀 Features
✅ 1. Automatic English SRT + word-level timestamps

Uses OpenAI Whisper (CLI)

Outputs:

<basename>.srt — English subtitles

<basename>.json — Detailed segment + word timestamps

✅ 2. Auto-generated word-level SRT

Converts Whisper’s JSON into a clean:

<basename>_words.srt

✅ 3. High-quality Japanese translation (GPT-5)

Translates the entire SRT in a single API call

Ensures:

Block numbers unchanged

Timecodes unchanged

No merging/splitting/reordering

Natural spoken Japanese, YouTube-ready

Output:

<basename>_ja.srt

✅ 4. Automatic Final Cut Pro XML (FCPXML)

Converts Japanese SRT into .fcpxml

Every subtitle line becomes a separate Basic Title item

Includes:

Proper offsets

Correct duration per subtitle

Font + style settings

Output:

<basename>_ja.fcpxml

📦 Requirements
Whisper CLI

Install via pip:

pip install -U openai-whisper

OpenAI API Key

Set environment variable:

export OPENAI_API_KEY="your-key-here"

Python 3.9+ required
📁 Input / Output Structure

Given input:

video.mp4


The script produces:

video.srt               # Whisper English subtitles
video.json              # Whisper word-level timestamps
video_words.srt         # Word-by-word SRT
video_ja.srt            # Japanese-translated SRT
video_ja.fcpxml         # Final Cut importable subtitle project

🔧 Usage

Run:

./subtitles.sh input.mp4


The script automatically detects existing output files and skips steps that are already completed.

🧠 Translation Rules (strict)

The translation step enforces:

Keep all SRT block numbers exactly the same

Keep all timestamps exactly the same

Do not merge or split lines

Translate only spoken text

Output valid SRT

Use natural conversational Japanese suitable for YouTube

Keep filler words minimal but natural

This ensures full compatibility with video editors like Final Cut Pro.

🧩 Final Cut Pro XML Export

The generated .fcpxml file:

Uses the Basic Title effect

Inserts each subtitle as an individual <title> element

Uses 1/25s frame duration (25 fps)

Automatically calculates:

Offset

Duration

Applies style:

Center alignment

Helvetica font

60 pt

White text

This can be imported directly into Final Cut Pro.

🔍 Troubleshooting
Whisper not found

Install:

pip install openai-whisper

JSON missing or empty

Delete old files and re-run:

rm *.json *.srt
./subtitles.sh input.mp4

OpenAI API issues

Ensure:

export OPENAI_API_KEY=<valid key>

📁 Example Directory Layout
project/
 ├── subtitles.sh
 ├── input.mp4
 ├── input.srt
 ├── input.json
 ├── input_words.srt
 ├── input_ja.srt
 └── input_ja.fcpxml

📄 License

MIT License — feel free to modify and reuse.

🙋 Support

If you'd like:

a GUI version

batch-processing for multiple videos

a workflow using the new OpenAI Responses API

automatic YouTube upload integration

Just ask!