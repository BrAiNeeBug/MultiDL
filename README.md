# BrAiNee's MultiDL v6

A dark-themed Windows GUI for downloading videos and audio via **yt-dlp** + **ffmpeg** — built in AutoIt, with full **Wine on Linux** compatibility.

---

## Features

- **Video download** — best quality MP4 (bestvideo + bestaudio, ffmpeg merge)
- **Audio download** — best quality MP3 extraction via ffmpeg
- **Playlist mode** — download entire playlists or single files
- **Live View** — watch a video in your default player *while* it downloads
- **Auto URL cleanup** — strips playlist parameters from single-video links
- **Start / Stop toggle** — cancel any running download at any time
- **PasteStart** — paste URL from clipboard and start immediately
- **Play last file** — reopen the last downloaded file directly from the GUI
- **CMD window toggle** — optionally show the yt-dlp console for debugging
- **One-click updater** — updates yt-dlp and ffmpeg to latest versions
- **Auto install** — downloads and installs yt-dlp + ffmpeg automatically on first run
- **Wine compatible** — runs on Linux under Wine without native tools

---

## Usage

### Normal Download

1. Paste a URL into the input field (or use **PasteStart**)
2. Choose format: **Video (MP4)** or **Audio (MP3)**
3. Choose mode: **Single** or **Playlist**
4. Click **Start** — progress bar and status update live
5. Click **> Play last File** when done, or **[>] View Downloads** to open the folder

### Live View

Click **LIVE** in the title bar to switch to Live View mode.

1. Paste a URL into the Live URL field (or use **PasteStart**)
2. Click **Start Live**
3. MultiDL downloads the video as `_watch_live.mp4` and opens it in your default player automatically — the file grows as it downloads
4. Click **Stop** to cancel, click **LIVE** again to return to normal mode

> The file `_watch_live.mp4` stays in the downloads folder after watching. It gets overwritten on the next Live session. Rename it if you want to keep it.

---

## Requirements

Nothing — MultiDL installs everything automatically on first launch:

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — downloaded from GitHub releases
- [ffmpeg](https://github.com/BtbN/FFmpeg-Builds) — downloaded and unpacked (~90 MB)
- [7-Zip](https://github.com/ip7z/7zip) — used temporarily for unpacking ffmpeg, latest version fetched via GitHub API

All binaries are stored in `.\bin\` next to the executable.

---

## File Structure

```
MultiDL.exe
bin\
    yt-dlp.exe
    ffmpeg.exe
    ffprobe.exe
MultiDL-Downloads\
    *.mp4 / *.mp3
    _watch_live.mp4
```

---

## Linux / Wine

MultiDL was built with Wine compatibility in mind. Run it like any other Windows `.exe` under Wine:

```bash
wine MultiDL.exe
```

yt-dlp and ffmpeg are Windows binaries — no native Linux tools needed.

---

## Built With

- [AutoIt v3](https://www.autoitscript.com/) — GUI and scripting
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — video/audio downloading
- [ffmpeg](https://ffmpeg.org/) — merging and audio conversion

---

## License

Do whatever you want with it.
