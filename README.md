# 🎬 Auto Subtitle Pipeline (Whisper → Translation → FCPXML)

This script provides a fully automated pipeline for generating English subtitles, word-level timestamps, Japanese translations, and Final Cut Pro–ready FCPXML files.

It is designed for YouTube creators, editors, and anyone needing fast, high-quality subtitle automation using Whisper, GPT, and Final Cut Pro.

---

## 🚀 Features

### 1. Automatic English Subtitles (Whisper)
Generates:
- `<basename>.srt` — English SRT  
- `<basename>.json` — Word-level timestamp data  

### 2. Automatic Word-Level SRT
Converts Whisper JSON into:
- `<basename>_words.srt`

### 3. Natural Japanese Translation (GPT-5)
- Translates the entire SRT in one API call  
- Preserves all timecodes and block numbers  
- No merging, splitting, or reordering  
- Produces natural conversational Japanese  
- Output:
  - `<basename>_ja.srt`

### 4. Final Cut Pro XML Export
- Generates FCPXML title items for each subtitle line  
- Auto-calculates offset and duration  
- Uses Basic Title with styling  
- Output:
  - `<basename>_ja.fcpxml`

---

## 📦 Requirements

### Whisper CLI
    pip install -U openai-whisper

### OpenAI API Key
    export OPENAI_API_KEY="your-key-here"

### Python 3.9+

---

## 📁 Input / Output Example

Input:
    video.mp4

Outputs:
    video.srt               # English SRT
    video.json              # Whisper JSON timestamps
    video_words.srt         # Word-level SRT
    video_ja.srt            # Japanese translated SRT
    video_ja.fcpxml         # Final Cut Pro XML

---

## 🔧 Usage

Run:
    ./subtitles.sh input.mp4

The script automatically skips any steps that already have output files.

---

## 🧠 Translation Rules (strict)

1. Keep SRT block numbers unchanged  
2. Keep timestamps unchanged  
3. Do not merge or split lines  
4. Translate text lines only  
5. Output valid SRT  
6. Use natural conversational Japanese  
7. Keep filler/reaction words simple  

---

## 🧩 Final Cut Pro XML Details

The generated FCPXML uses:

- Basic Title  
- 25 fps (`1/25s` frameDuration)  
- Center alignment  
- Helvetica Regular  
- 60 pt white text  
- One `<title>` per subtitle line  

This can be imported directly into Final Cut Pro.

---

## 🔍 Troubleshooting

Whisper not found:
    pip install openai-whisper

JSON missing or empty:
    rm *.json *.srt
    ./subtitles.sh input.mp4

API key issues:
    export OPENAI_API_KEY=your-key

---

## 📁 Example Directory Layout

    project/
     ├── subtitles.sh
     ├── input.mp4
     ├── input.srt
     ├── input.json
     ├── input_words.srt
     ├── input_ja.srt
     └── input_ja.fcpxml

---

## 📄 License

MIT License.

---

## 🙋 Support

If you want enhancements such as:

- GUI version  
- Batch processing  
- OpenAI Responses API version  
- Automated YouTube upload integration  

Just let me know!
