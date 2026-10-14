# BrAiNee's MultiDL v8.3.0.3 (14.10.2026)

A dark-themed Windows GUI for downloading videos and audio via **yt-dlp** + **ffmpeg**, featuring the built-in media player **BrAiNPlay**. Built with AutoIt, with compatibility considerations for running under Wine on Linux.

<img width="1120" height="910" alt="image" src="https://github.com/user-attachments/assets/8233019e-0292-489d-818a-70ccb09bd5f2" />


---

## Features

### Downloader

- **Video download**: best available video and audio quality, merged into MP4 using ffmpeg.
- **Audio download**: best available audio extracted as MP3 via ffmpeg.
- **Live View**: watch a video while it downloads.
- **Playlist mode**: download entire playlists or individual files.
- **Auto URL cleanup**: removes playlist parameters from single-video links.
- **Clipboard monitoring**: detect supported URLs copied to the clipboard.
- **Automatic link processing**: configure how detected links are handled.
- **Domain link detection**: recognize supported links based on their domain.
- **Start / Stop toggle**: cancel a running download.
- **Play last file**: reopen the last downloaded file directly from the GUI.
- **View Downloads**: open the download directory.
- **CMD window toggle**: optionally show the yt-dlp console for debugging.
- **One-click updater**: update yt-dlp and ffmpeg using the integrated update functionality.
- **Automatic installation**: download and set up yt-dlp, ffmpeg, and Deno on first run.

### Built-in Player: BrAiNPlay

- **Audio and video playback** for supported media files.
- **Integrated player interface**: switch between the downloader and player using the title-bar player button.
- **Download folder as playlist**: `MultiDL-Downloads` is loaded whenever the player opens. Files already in the playlist are not added twice.
- **Click-to-seek waveform**: the waveform reflects the current track; click it to seek.
- **Volume and balance**: draggable sliders, with settings remembered between sessions.
- **Playlist tools**: add files, add folders, remove tracks, clear the playlist, and save or load `.m3u` playlists.
- **Automatic playlist saving**: the last playlist is saved automatically.
- **Shuffle and loop**: playback modes for your music collection.
- **Video playback**: fullscreen on the active monitor or a window sized to the video.
- **VIDEO ON / OFF**: toggle the video window while a video is playing.
- **Player selection**: choose the available playback method through the options, where supported.
- **Keyboard shortcuts and media keys**: control playback without relying on the mouse.
- **Minimize to tray**: playback continues in the background, and the tray tooltip displays the current track.

### Options Menu

The options menu provides access to configurable application behavior.

Depending on the selected options and the current version, configuration includes:

- **Clipboard Watcher**: enable or disable clipboard monitoring for supported links.
- **Automatic Processing**: control the automatic handling of detected links.
- **Domain Links**: configure domain-based link detection where supported.
- **Player Selection**: select an available playback method.
- **Playback and application settings**: configure the options exposed by the current build.

Settings and available choices depend on the components installed and the functionality implemented in the current version.

---

## Usage

### Normal Download

1. Paste a URL into the input field
2. Choose the format: **Video (MP4)**, **Audio (MP3)**, or **Live**.
3. Choose the mode: **Single** or **Playlist**.
4. Click **Start**. Progress and status information update while the download runs.
5. Click **Play last File** to open the downloaded file, or **View Downloads** to open the download folder.

### Clipboard Monitoring and Automatic Processing

1. Open the options menu.
2. Enable the clipboard watcher if you want MultiDL to monitor copied links.
3. Configure automatic processing and domain link handling according to your preferences.
4. Copy a supported URL to the clipboard and let MultiDL handle it according to the active settings.

The links that can be detected and the actions performed automatically depend on the enabled options and supported URL formats.

### Live View

Select **Live** in the Format row.

1. Paste a URL into the input field
2. Click **Start**.
3. MultiDL downloads the video as `_watch_live.mp4` while you watch. The file grows as the download progresses.
4. Click **Stop** to cancel the operation. Select **Video** or **Audio** again to return to normal downloads.

The format cannot be changed while a live stream is running.

> The file `_watch_live.mp4` remains in the downloads folder after playback. It is overwritten during the next Live session. Rename it if you want to keep it. Files starting with `_` are not added to the player playlist.

### Player

Click the **player button** in the title bar to switch between the downloader and BrAiNPlay.

- Click the **waveform** to seek through the current track.
- Drag the **VOL** slider to adjust volume.
- Drag the **BAL** slider to adjust left/right audio balance.
- Click a track in the playlist to play it.
- Use the playlist controls to add files or folders, remove tracks, clear the playlist, and save or load `.m3u` playlists.
- Use **Shuffle** or **Loop** to change playback behavior.
- Use the video controls to toggle video visibility or change the display mode.
- Click the **minimize button** in the title bar to hide the player in the system tray.
- Click the tray icon to restore the window. To quit, restore the window and use the **X** button.

### Keyboard Shortcuts

The following shortcuts are available in player mode.

| Key | Action |
|---|---|
| `Space` | Play / pause |
| `S` | Stop |
| `N` / `P` | Next / previous track |
| `←` / `→` | Seek 10 seconds backward / forward |
| `Ctrl+↑` / `Ctrl+↓` | Volume up / down |
| `M` | Mute |
| `Del` | Remove selected track from the playlist |
| `V` | Show / hide the video window |
| `F` | Fullscreen |
| `W` | Window mode, sized to the video |
| `Esc` | Leave fullscreen |
| `+` / `-` / `0` | Zoom in / out / reset video zoom |
| `A` | Switch audio track |
| `D` | Move video to the next monitor |

The multimedia keys for play/pause, next, previous, and stop work globally while the player is in use, including when the window is minimized to the tray.

A short press on next/previous changes the track. Holding the key fast-forwards or rewinds.

Media keys are released when the player is closed and nothing is playing, allowing other media players to use them.

Letter shortcuts are active only in player mode, so they do not interfere with typing in the downloader's URL field.

---

## ♥ Suno ♥

Single songs (`suno.com/song/<id>`) work like other supported links. Video, Audio, and Live View are available where supported.

**Not supported on purpose:**

- Playlists
- Batch downloading multiple songs at once
- Private and unpublished songs

This is a deliberate limitation, not a bug. Only single-song links are handled.

---

## Requirements

MultiDL automatically installs the supported dependencies on first launch.

The application fetches supported binaries from their respective sources. On Wine/Linux, the setup process may retrieve a compatible 7-Zip release through the GitHub API for extraction.

All downloader binaries are stored in the `bin\` directory next to the application executable.

### Updating Components

Use the integrated updater to update supported components, including yt-dlp and ffmpeg.

Keep the application files together and avoid mixing files from different releases.

---

## File Structure

```text
MultiDL.exe
bin\
    yt-dlp.exe
    ffmpeg.exe
    ffprobe.exe
    deno.exe

MultiDL-Downloads\
    *.mp4
    *.mp3
    _watch_live.mp4

%AppData%\BrAiNPlay\
    brainplay.ini
    last.m3u
```

### Configuration Files

- `brainplay.ini`: stores player settings such as volume, balance, shuffle, loop, and video mode.
- `last.m3u`: stores the automatically saved playlist.

The options menu may expose additional application settings. Refer to the current source code for the exact storage location and supported configuration entries.

---

## Linux / Wine

MultiDL is a Windows application built with AutoIt and designed with Wine compatibility in mind.

Run it under Wine like any other Windows executable:

```bash
wine MultiDL.exe
```

yt-dlp, ffmpeg, and the other bundled components are Windows binaries. A separate native Linux installation of these tools is not required for the Windows-based workflow.

### Video Playback

BrAiNPlay uses Windows multimedia facilities for playback. Depending on the selected player and the current implementation, video playback may use the Windows multimedia engine or an external playback component.

When the configured video playback method uses `ffplay.exe`, the executable must be available in the expected location along with its required supporting files.

Under Wine, some video formats may not play correctly because Windows multimedia components, codecs, or external playback methods may behave differently from a native Windows environment.

### Known Limitations

- Some Windows-specific functionality may behave differently under Wine.
- Video playback depends on the selected playback method and installed components.
- Some formats may require compatible codecs or an external player.
- Clipboard monitoring and process handling may behave differently depending on the desktop environment.
- Automatic installation and updating require network access and access to the relevant download sources.
- Compatibility with every Linux distribution, Wine version, or media format is not guaranteed.

For the most predictable behavior, use a supported Windows environment.

---

## Built With

- [AutoIt v3](https://www.autoitscript.com/) for the GUI and scripting.
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) for video and audio downloading.
- [ffmpeg](https://ffmpeg.org/) for merging and audio conversion.
- [Deno](https://github.com/denoland/deno) as the JavaScript runtime used by yt-dlp for certain extractors.
- [7-Zip](https://github.com/ip7z/7zip) for temporary extraction on Wine/Linux.
- [BrAiNPlay](https://www.autoitscript.com/forum/topic/213899-brainplay-intuitiveplayer/) for the integrated media player.

---

## Repository

- [Source code](https://github.com/BrAiNeeBug/MultiDL)
- [Main script: MultiDL.au3](https://github.com/BrAiNeeBug/MultiDL/blob/main/MultiDL.au3)
- [Releases](https://github.com/BrAiNeeBug/MultiDL/releases)

## License

Do whatever you want with it.
