# BrAiNee's MultiDL v8.2.0.6 (09.10.2026)

A dark-themed Windows GUI for downloading videos and audio via **yt-dlp** + **ffmpeg** — now with a built-in media player (**BrAiNPlay**). Built in AutoIt, with **Wine on Linux** compatibility for the downloader.

---

## Features

### Downloader

- **Video download** — best quality MP4 (bestvideo + bestaudio, ffmpeg merge)
- **Audio download** — best quality MP3 extraction via ffmpeg
- **Live View** — watch a video *while* it downloads
- **Playlist mode** — download entire playlists or single files
- **Auto URL cleanup** — strips playlist parameters from single-video links
- **Start / Stop toggle** — cancel any running download at any time
- **PasteStart** — paste URL from clipboard and start immediately
- **Play last file** — reopen the last downloaded file directly from the GUI
- **CMD window toggle** — optionally show the yt-dlp console for debugging
- **One-click updater** — updates yt-dlp and ffmpeg to latest versions
- **Auto install** — downloads and installs yt-dlp + ffmpeg + deno automatically on first run

### Built-in player (BrAiNPlay)

- **Plays everything you download** — audio and video, opened with the player button in the title bar
- **Download folder as playlist** — `MultiDL-Downloads` is loaded into the playlist every time the player opens (files already in the list are not added twice)
- **Click-to-seek waveform** — the waveform reflects the actual track; click it to jump anywhere
- **Volume and balance** — draggable sliders, remembered between sessions
- **Playlist tools** — add files, add folder, remove, clear, save and load as `.m3u`; the last playlist is autosaved
- **Shuffle and loop**
- **Video support** — fullscreen on the active monitor, or a window at video size; the **VIDEO ON / OFF** button (top right, visible while a video plays) toggles the video window
- **Keyboard and media keys** — see the shortcut table below
- **Minimize to tray** — the player keeps playing in the background, the tray tooltip shows the current track

---

## Usage

### Normal Download

1. Paste a URL into the input field (or use **PasteStart**)
2. Choose the format: **Video (MP4)**, **Audio (MP3)** or **Live**
3. Choose the mode: **Single** or **Playlist**
4. Click **Start** — progress bar and status update live
5. Click **> Play last File** when done, or **[>] View Downloads** to open the folder

### Live View

Select **Live** in the Format row.

1. Paste a URL into the input field (or use **PasteStart**)
2. Click **Start**
3. MultiDL downloads the video as `_watch_live.mp4` while you watch — the file grows as it downloads
4. Click **Stop** to cancel, select **Video** or **Audio** again to return to normal downloads

The format can't be changed while a live stream is running.

> The file `_watch_live.mp4` stays in the downloads folder after watching. It gets overwritten on the next Live session. Rename it if you want to keep it. Files starting with `_` are not added to the player playlist.

### Player

Click the **play button** in the title bar to switch between the downloader and the player.

- Click the **waveform** to seek, drag the **VOL** and **BAL** bars to change volume and balance
- Click a track in the playlist to play it
- Click the **–** button in the title bar to hide the window in the tray, a single click on the tray icon brings it back (to quit, restore the window first and use the **x** button)

#### Keyboard shortcuts (player mode)

| Key | Action |
|---|---|
| `Space` | Play / pause |
| `S` | Stop |
| `N` / `P` | Next / previous track |
| `←` / `→` | Seek 10 seconds back / forward |
| `Ctrl+↑` / `Ctrl+↓` | Volume up / down |
| `M` | Mute |
| `Del` | Remove selected track from the playlist |
| `V` | Show / hide the video window |
| `F` | Fullscreen |
| `W` | Window mode (video size) |
| `Esc` | Leave fullscreen |
| `+` / `-` / `0` | Zoom in / out / reset (video) |
| `A` | Switch audio track |
| `D` | Move video to the next monitor |

The multimedia keys (play/pause, next, previous, stop) work globally while the player is in use, also when the window is in the tray. A short press on next/previous changes the track, holding the key fast-forwards / rewinds. They are released again when the player is closed and nothing is playing, so other players keep their keys. The letter shortcuts are only active in player mode, so they never interfere with typing in the URL field.

---

## ♥Suno♥

Single songs (`suno.com/song/<id>`) work like any other link — Video/Audio, Live View, all of it.

**Not supported on purpose:** playlists / batch-downloading multiple songs at once / private and unpublic songs.

This is a deliberate limitation, not a bug — only single-song links are handled.

---

## Requirements

Nothing — MultiDL installs everything automatically on first launch:

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — downloaded from GitHub releases
- [ffmpeg](https://github.com/BtbN/FFmpeg-Builds) — downloaded and unpacked (~170 MB)
- [deno](https://github.com/denoland/deno) — JS runtime for yt-dlp
- [7-Zip](https://github.com/ip7z/7zip) — used temporarily for unpacking on Wine/Linux, latest version fetched via GitHub API

All binaries are stored in `.\bin\` next to the executable.

---

## File Structure

```
MultiDL.exe
bin\
    yt-dlp.exe
    ffmpeg.exe
    ffprobe.exe
    deno.exe
MultiDL-Downloads\
    *.mp4 / *.mp3
    _watch_live.mp4

%AppData%\BrAiNPlay\
    brainplay.ini       (player settings: volume, balance, shuffle, loop, video mode)
    last.m3u            (autosaved playlist)
```

---

## Linux / Wine

MultiDL was built with Wine compatibility in mind. Run it like any other Windows `.exe` under Wine:

```bash
wine MultiDL.exe
```

yt-dlp and ffmpeg are Windows binaries — no native Linux tools needed.

The player uses the Windows multimedia engine (MCI) and, for video formats MCI can't open, the Windows Media Player component. Under Wine, playback of some video formats may therefore be limited.

---

## Built With

- [AutoIt v3](https://www.autoitscript.com/) — GUI and scripting
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — video/audio downloading
- [ffmpeg](https://ffmpeg.org/) — merging and audio conversion
- [deno](https://github.com/denoland/deno) — JS runtime yt-dlp needs for some extractors
- [7-Zip](https://github.com/ip7z/7zip) — temporary unpacking on Wine/Linux
- [BrAiNPlay](https://www.autoitscript.com/forum/topic/213899-brainplay-intuitiveplayer/) — the built-in player

---

## License

Do whatever you want with it.
