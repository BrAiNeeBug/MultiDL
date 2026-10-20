# BrAiNee's MultiDL v8.5.1.1 (20.10.2026)

A dark-themed Windows GUI for downloading videos and audio via **yt-dlp** + **ffmpeg**, featuring the built-in media player **BrAiNPlay**. Built with AutoIt, with compatibility considerations for running under Wine on Linux.

<img width="1124" height="1017" alt="image" src="https://github.com/user-attachments/assets/dace51d0-a488-465d-a7e5-9cb017d12287" />

---

## Features

### Downloader

- **Video download**: best available video and audio quality, merged into MP4 using ffmpeg.
- **Audio download**: best available audio extracted as MP3 via ffmpeg.
- **Live View**: watch a video while it downloads. With the internal player enabled it opens in BrAiNPlay, otherwise in your system player.
- **Single / Multi mode**: download one file, or all files of a link (playlists). In Single mode a pure playlist link (e.g. a YouTube `playlist?list=...` link, which cannot be cleaned) loads only its first item.
- **Download list**: links are collected in a small list below the input field and downloaded one after another. Every link keeps the format (Video/Audio, Single/Multi) that was selected when it was added.
- **Auto URL cleanup**: in Single mode, playlist parameters are removed from single-video links (silently, no extra info line). Multi mode keeps the full link.
- **Status bar info**: shows the selected format and mode (e.g. `Video (MP4): best video quality | Single: download one file`).
- **Clipboard monitoring**: every supported URL copied to the clipboard is added to the download list.
- **Automatic mode**: links that are added start downloading by themselves, also while another download is running (they wait in the list).
- **Domain link detection**: recognize links without `http(s)`, e.g. `example.com/watch?v=...`.
- **Start / Stop button = progress bar**: the button fills with the download progress. While a list with several links runs, it also shows the position, e.g. `Stop 45% (2/5)`.
- **Play last file**: reopen the last downloaded file directly from the GUI.
- **View Downloads**: open the download directory.
- **Tray icon**: always present; it blinks while a download is running and its tooltip shows the download state.
- **Single instance**: a second start of MultiDL does not open another window, it shows the running one (also when it sits in the tray).
- **English / German UI**: switch the language in the options menu (English is the default).
- **CMD window toggle**: optionally show the yt-dlp console for debugging.
- **One-click tool updater**: update yt-dlp, ffmpeg and Deno from the options menu.
- **Self-update from GitHub**: an update badge appears in the title bar when a newer release exists; one click replaces `MultiDL.exe` and restarts (see *Updating*).
- **Automatic installation**: download and set up yt-dlp, ffmpeg, and Deno on first run.

### Download List

The list sits directly under the input field.

| Mark | Meaning |
|---|---|
| `[  ]` | waiting |
| `[>>]` | running |
| `[OK]` | done |
| `[!!]` | failed |

- **Add**: click the green **+** (or press `Enter`) to put the link of the input field into the list. Links copied to the clipboard are added automatically (clipboard watcher on).
- **Start**: works the list off from top to bottom. A link still in the input field is added first. A summary above the list shows how many links are running, waiting, done or failed.
- **Stop**: stops the running download; the link waits again and **Start** continues the list.
- **REMOVE / CLEAR**: remove the selected link, or clear the whole list. A running download is never removed; stop it first.
- **Duplicates**: a link that is already waiting or running is not added twice.
- **New list**: when nothing is open any more, the next added link starts a fresh list and the old `[OK]` / `[!!]` lines go away.
- When the list is finished the status bar shows the result, and the tray icon stops blinking.
- **Live** is always a single stream: it uses the input field and does not use the list.

### Built-in Player: BrAiNPlay

- **Audio and video playback** for supported media files.
- **Integrated player interface**: switch between the downloader and player using the title-bar player button (it is highlighted on mouse-over).
- **Download folder as playlist**: `MultiDL-Downloads` is synced whenever the player opens and then every few seconds, **also while a download is running**. New files show up as soon as they are finished; half-written files and yt-dlp temp files are skipped. Files already in the playlist are not added twice, and a track you removed stays removed until you reopen the player.
- **Manual playlists**: after loading an `.m3u` with **LOAD**, the playlist no longer follows the download folder. **CLEAR** switches the automatic sync back on.
- **Click-to-seek waveform**: the waveform reflects the current track; click it to seek.
- **Volume and balance**: draggable sliders, with settings remembered between sessions. They also work for videos played through ffplay: ffplay cannot change them while running, so it restarts at the same position shortly after you release the slider.
- **Playlist tools**: add files, add folders, remove tracks, clear the playlist, and save or load `.m3u` playlists.
- **Automatic playlist saving**: the last playlist is saved automatically.
- **Shuffle and loop**: playback modes for your music collection.
- **Video playback**: fullscreen on the active monitor or a window sized to the video. `F` switches between the two in every play mode.
- **VIDEO ON / OFF**: toggle the video while a video is playing. Works for the built-in video window and for videos played through ffplay (OFF = sound only, ffplay restarts at the same position). Closing the video window with its X button switches the video off and updates the button.
- **Keyboard shortcuts and media keys**: control playback without relying on the mouse.
- **Minimize to tray**: playback continues in the background, and the tray tooltip displays the current track.

### Options Menu

The options menu opens when you click the app name in the title bar (it is highlighted on mouse-over).

| Section | Entry | What it does |
|---|---|---|
| Link-Detection | **Check for Links in Clipboard.** | Clipboard watcher: copied links are added to the download list. |
| | **Resolve Links without http(s)** | Also detect links like `example.com/path`. |
| | **Automatic-Mode** | Added links start downloading automatically. |
| Player | **Use internal player (BrAiNPlay)** | On: Play last File and Live open BrAiNPlay (and the BP button is shown). Off: the system player is used. |
| Tools | **Show download console** | Show / hide the yt-dlp console window. |
| | **Update all tools** | Update yt-dlp, ffmpeg and Deno. |
| Program | **Language** | Switch the UI between English and German. |
| | **About** | Version, short info and links to the GitHub repository and the releases page. |

---

## Usage

### Normal Download

1. Paste a URL into the input field and click **+** (or press `Enter`). Repeat for more links.
2. Choose the format: **Video (MP4)**, **Audio (MP3)**, or **Live**.
3. Choose the mode: **Single** or **Multi**.
4. Click **Start**. The list is worked off one link after another; progress and status information update while it runs.
5. Click **Play last File** to open the downloaded file, or **View Downloads** to open the download folder.

A single link also works without **+**: type or paste it and just click **Start**.

### Clipboard Monitoring and Automatic Processing

1. Open the options menu.
2. Enable **Check for Links in Clipboard.** if you want MultiDL to monitor copied links.
3. Enable **Automatic-Mode** if the list should start by itself; otherwise click **Start** when you are done collecting links.
4. Copy URLs: each one is added to the download list. Only one link per clipboard content is taken.

While the player view is open, the clipboard is only watched in Automatic-Mode.

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
- Click the **minimize button** in the title bar to hide the window in the system tray.
- Click the tray icon to restore the window (a click while the window is open brings it to the front). To quit, use the **X** button.

### Keyboard Shortcuts

In the downloader, `Enter` adds the link of the input field to the download list.

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

Use the integrated updater (options menu, **Update all tools**) to update yt-dlp, ffmpeg and Deno.

### Updating MultiDL itself

On start, `MultiDL.exe` copies itself to `bin\~MultiDL.exe`, starts that copy and exits. This way `MultiDL.exe` is never locked while the program runs and can simply be replaced.

When a newer release exists, an update badge appears in the title bar. Click it to download `MultiDL.exe` from the latest GitHub release (temporarily saved as `MultiDL_new.exe`), replace the main file and restart. The release needs an asset named `MultiDL.exe`. If the normal download fails, MultiDL tries the `curl.exe` that ships with Windows 10/11, and an error message names the reason. You can also just overwrite `MultiDL.exe` by hand while MultiDL is running.

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
    ffplay.exe
    deno.exe

MultiDL-Downloads\
    *.mp4
    *.mp3
    _watch_live.mp4

%AppData%\MultiDL\
    settings.ini

%AppData%\BrAiNPlay\
    brainplay.ini
    last.m3u
```

### Configuration Files

- `settings.ini`: stores the options menu settings (clipboard watcher, domain links, automatic mode, internal player, language).
- `brainplay.ini`: stores player settings such as volume, balance, shuffle, loop, and video mode.
- `last.m3u`: stores the automatically saved playlist.

The download list itself is not saved; it is empty after a restart.

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
- BrAiNPlay(light) no logging, no mqtt stuff currently.

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
