# BrAiNee's MultiDL v8.5.0.0 (16.10.2026)

A dark-themed Windows GUI for downloading videos and audio via **yt-dlp** + **ffmpeg**, featuring the built-in media player **BrAiNPlay**. Built with AutoIt, with compatibility considerations for running under Wine on Linux.

<img width="1124" height="1007" alt="image" src="https://github.com/user-attachments/assets/70c69b5d-df36-47ec-8e95-efdd465a2219" />


---

## Features

### Downloader

- **Video download**: best available video and audio quality, merged into MP4 using ffmpeg.
- **Audio download**: best available audio extracted as MP3 via ffmpeg.
- **Live View**: watch a video while it downloads. With the internal player enabled it opens in BrAiNPlay, otherwise in your system player.
- **Playlist mode**: download entire playlists or individual files.
- **Auto URL cleanup**: removes playlist parameters from single-video links (silently, no extra info line).
- **Status bar info**: shows the selected format and mode (e.g. `Video (MP4): best video quality | Single: download one file`).
- **Clipboard monitoring**: detect supported URLs copied to the clipboard.
- **Automatic link processing**: configure how detected links are handled.
- **Domain link detection**: recognize supported links based on their domain.
- **Start / Stop toggle**: cancel a running download.
- **Play last file**: reopen the last downloaded file directly from the GUI.
- **View Downloads**: open the download directory.
- **CMD window toggle**: optionally show the yt-dlp console for debugging.
- **One-click tool updater**: update yt-dlp, ffmpeg and Deno from the options menu.
- **Self-update from GitHub**: an update badge appears in the title bar when a newer release exists; one click replaces `MultiDL.exe` and restarts (see *Updating*).
- **Automatic installation**: download and set up yt-dlp, ffmpeg, and Deno on first run.

### Built-in Player: BrAiNPlay

- **Audio and video playback** for supported media files.
- **Integrated player interface**: switch between the downloader and player using the title-bar player button.
- **Download folder as playlist**: `MultiDL-Downloads` is synced whenever the player opens and then every few seconds, **also while a download is running**. New files show up as soon as they are finished; half-written files and yt-dlp temp files are skipped. Files already in the playlist are not added twice, and a track you removed stays removed until you reopen the player.
- **Manual playlists**: after loading an `.m3u` with **LOAD**, the playlist no longer follows the download folder. **CLEAR** switches the automatic sync back on.
- **Click-to-seek waveform**: the waveform reflects the current track; click it to seek.
- **Volume and balance**: draggable sliders, with settings remembered between sessions. They also work for videos played through ffplay: ffplay cannot change them while running, so it restarts at the same position shortly after you release the slider.
- **Playlist tools**: add files, add folders, remove tracks, clear the playlist, and save or load `.m3u` playlists.
- **Automatic playlist saving**: the last playlist is saved automatically.
- **Shuffle and loop**: playback modes for your music collection.
- **Video playback**: fullscreen on the active monitor or a window sized to the video. `F` switches between the two in every play mode.
- **VIDEO ON / OFF**: toggle the video while a video is playing. Works for the built-in video window and for videos played through ffplay (OFF = sound only, ffplay restarts at the same position). Closing the video window with its X button switches the video off and updates the button.
- **Player selection**: choose the available playback method through the options, where supported.
- **Keyboard shortcuts and media keys**: control playback without relying on the mouse.
- **Minimize to tray**: playback continues in the background, and the tray tooltip displays the current track.

### Options Menu

The options menu opens when you click the app name in the title bar (it is highlighted on mouse-over).

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
4. With **Use internal player (BrAiNPlay)** enabled, the stream opens in BrAiNPlay (played through ffplay, with the VIDEO ON / OFF switch) and the window switches to the player view, like **Play last File**. With the option disabled, your system player is used.
5. To stop, click the **player button** to return to the download view and click **Stop**. The live file is then removed from the playlist. Select **Video** or **Audio** again to return to normal downloads.

The format cannot be changed while a live stream is running.

> The file `_watch_live.mp4` remains in the downloads folder after playback. It is overwritten during the next Live session. Rename it if you want to keep it. Files starting with `_` are not added automatically to the player playlist and are not saved in `last.m3u`.

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
| `V` | Video on / off (all play modes) |
| `F` | Switch between fullscreen and window (all play modes); with the video off it turns the video on in fullscreen |
| `+` / `-` / `0` | Zoom in / out / reset video zoom |
| `A` | Switch audio track |
| `D` | Move video to the next monitor |

`V` and `F` also work while the ffplay window has the focus (Live and ffplay videos). The other ffplay keys (for example `Space`, `S`, `M`, arrow keys) are then handled by ffplay itself. `Esc` in the ffplay window quits ffplay and stops the track.

`Esc` never closes MultiDL; only the **X** button does. With the built-in video player (WMP fallback) there is no window mode, so `F` leaves its fullscreen and turns the video off.

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

Use the integrated updater (options menu) to update yt-dlp, ffmpeg and Deno.

### Updating MultiDL itself

On start, `MultiDL.exe` copies itself to `bin\~MultiDL.exe`, starts that copy and exits. This way `MultiDL.exe` is never locked while the program runs and can simply be replaced.

When a newer release exists, an update badge appears in the title bar. Click it to download `MultiDL.exe` from the latest GitHub release, replace the main file and restart. The release needs an asset named `MultiDL.exe`. You can also just overwrite `MultiDL.exe` by hand while MultiDL is running.

If MultiDL was not started through the copy (for example when run from the script), the badge only opens the release page.

Keep the application files together and avoid mixing files from different releases.

---

## File Structure

```text
MultiDL.exe
bin\
    ~MultiDL.exe        (running copy, created automatically)
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
