#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=multidl.ico
#AutoIt3Wrapper_Outfile_x64=MultiDL.exe
#AutoIt3Wrapper_Res_Fileversion=8.5.0.0
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=None
#AutoIt3Wrapper_Add_Includes=n
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_AU3Check_Parameters=-w 1 -w 2 -w- 4 -w 6
#AutoIt3Wrapper_Run_Stop_OnError=y
#AutoIt3Wrapper_Run_After=del /f /q %scriptdir%\%scriptfile%_stripped.au3
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/rel
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so /rm
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include-once
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <GuiStatusBar.au3>
#include <FontConstants.au3>
#include <ColorConstants.au3>
#include <WinAPIFiles.au3>
#include <WinAPI.au3>
#include <WindowsStylesConstants.au3>
#include <InetConstants.au3>
#include <ListBoxConstants.au3>
#include <Array.au3>
#include <Math.au3>
#include <StructureConstants.au3>
#include <WinAPISys.au3>
#include <WinAPISysWin.au3>
#include <TrayConstants.au3>
#include <TabConstants.au3>
; ---- Konstanten ----
Global Const $APP_TITLE = "BrAiNee's MultiDL v8.5"
Global Const $APP_DIR = (@Compiled And StringLeft(@ScriptName, 1) = "~") ? StringLeft(@ScriptDir, StringInStr(@ScriptDir, "\", 0, -1) - 1) : @ScriptDir ; folder of MultiDL.exe (the ~ copy runs from bin)
Global Const $BIN_DIR = $APP_DIR & "\bin"
Global Const $DL_DIR = $APP_DIR & "\MultiDL-Downloads"
Global Const $YTDLP_EXE = $BIN_DIR & "\yt-dlp.exe"
Global Const $FFMPEG_EXE = $BIN_DIR & "\ffmpeg.exe"
Global Const $DENO_EXE = $BIN_DIR & "\deno.exe"
Global Const $FFPLAY_EXE = $BIN_DIR & "\ffplay.exe"
Global Const $CLR_BG = 0x0F0F0F
Global Const $CLR_PANEL = 0x1A1A1A
Global Const $CLR_ACCENT = 0xFF0000
Global Const $CLR_TEXT = 0xF0F0F0
Global Const $CLR_MUTED = 0x888888
Global Const $CLR_INPUT = 0x252525
; ---- Aktuelle Version (muss zum AutoIt3Wrapper_Res_Fileversion oben passen) ----
Global Const $APP_VERSION = "8.5.0.0"
Global Const $GH_REPO = "BrAiNeeBug/MultiDL"
; ---- Start from a copy (~MultiDL.exe), so MultiDL.exe itself is never locked and can be replaced by an update ----
Global $g_sRemoteVer = "" ; newer version found on GitHub (set by _CheckForUpdate)
Global $g_sPlayReq = "" ; file the main loop should open in BrAiNPlay (Play last File / live view)
Global $g_bPLManual = False ; True after a playlist was loaded by hand -> the player no longer follows the download folder
Global $g_sKnown = "|" ; files of the download folder the player already took care of (a REMOVEd track stays removed)
Global $g_aSeenP[0], $g_aSeenS[0], $g_tPLSync = TimerInit(), $g_bPruneNeed = False
; ---- Link-Watcher / Automatik-Optionen ----
Global Const $CFG_FILE = @AppDataDir & "\MultiDL\settings.ini"
DirCreate(@AppDataDir & "\MultiDL")
Global $g_bClipWatch = (IniRead($CFG_FILE, "features", "clipboard_watch", "1") = "1")
Global $g_bAutoStart = (IniRead($CFG_FILE, "features", "auto_start", "0") = "1")
Global $g_bDomainLinks = (IniRead($CFG_FILE, "features", "domain_links", "1") = "1")
Global $g_bUseBP = (IniRead($CFG_FILE, "features", "use_brainplay", "1") = "1") ; False = Play last File opens the system player
Global $g_sLastClipboard = "", $g_sLastAutoURL = "", $g_tClipPoll = TimerInit()
Global $g_hOptGUI = 0, $g_hOptClip = 0, $g_hOptDomain = 0, $g_hOptAuto = 0, $g_hOptClose = 0, $g_hOptConsole = 0, $g_hOptUpdate = 0, $g_hOptBP = 0, $g_hOptMulti = 0, $g_hOptLang = 0
Global $g_bMultiInst = (IniRead($CFG_FILE, "features", "multi_instance", "0") = "1") ; False (default) = only one MultiDL at a time
Global $g_sLang = IniRead($CFG_FILE, "features", "language", "en") ; UI language: "en" (default) or "de"
If $g_sLang <> "de" Then $g_sLang = "en"
Global $g_bShowReq = False, $g_tFFKey = TimerInit() ; a second start asked this instance to show its window / ffplay key poll timer
; ---- single instance: a second start shows the running window (also from the tray) and quits - before the copy/relaunch dance ----
_SingleInstance(False)
_SelfRelaunch()
_SingleInstance(True) ; the instance that stays takes the mutex
; ---- SooS added ffmpeg-unzip debug ----
Global $g_sUnzipDebug = ""
; ---- Modus: False = Video, True = MP3 ----
Global $bMP3Mode = False
; ---- Multi-Modus: False = einzelnes Video (Single), True = ganze Playlist (Multi) ----
Global $BP_bPlaylistMode = False
Global $g_sRawLink = "", $g_sCleanLink = "" ; full link vs. cleaned link shown in the input (Single mode)
Global $g_bLiveSel = False ; Live selected: Single/Multi is switched off (a live stream is always a single stream)
; ---- CMD-Fenster sichtbar? ----
Global $bShowCMD = False
; ---- Start-Button-Zustand (nur bei Aenderung neu zeichnen, sonst flackert er) ----
Global $g_iStartState = -1
Global Const $PROG_Y = 266, $PROG_H = 38 ; the Start/Stop button IS the progress bar (position / height)
; ---- Aktueller yt-dlp Prozess Handle ----
Global $hDLProc = 0
; ---- Download-Fehler erkannt ----
Global $bDLFailed = False
Global $sDLError = ""
; ---- yt-dlp Bot-Check: einmaliger Retry mit --force-ipv4 ----
Global $g_bIPv4Retried = False
Global $g_bBotBlock = False
Global $g_sDownloadCMD = ""
Global $g_sLiveCMD = ""
; ---- Zuletzt heruntergeladene Datei (fuer Play-Button) ----
Global $sLastFile = ""
Global $BP_bPlayerOpened = False
Global $BP_pFF = 0, $BP_fFF = False ; BrAiNPlay: video played through ffplay (pid / active)
; ---- BrAiNPlay test integration mode ----
Global $BP_bPlayerMode = False
; ---- Zeitpunkt an dem der Live-Download gestartet wurde (fuer Player-Grace-Period) ----
Global $g_iLiveStartTick = 0
; ---- Verwaiste Prozesse von einem Absturz aufraeumen, dann Startup Check ----
_KillStaleProcesses()
_StartupCheck()
; ---- GUI aufbauen ----
Global $hGUI = GUICreate($APP_TITLE, 560, 524, -1, -1, $WS_POPUP + $WS_BORDER)
GUISetBkColor($CLR_BG, $hGUI)
; Titelleiste
Local $hTitleBar = GUICtrlCreateLabel("", 0, 0, 560, 36)
GUICtrlSetBkColor($hTitleBar, $CLR_PANEL)
Local $hTitleText = GUICtrlCreateLabel($APP_TITLE, 20, 9, 150, 20)
GUICtrlSetFont($hTitleText, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hTitleText, $CLR_TEXT)
GUICtrlSetBkColor($hTitleText, $CLR_PANEL)
GUICtrlSetTip($hTitleText, _L("Options"))
; Update-Hinweis (nur sichtbar wenn neue Version gefunden wurde)
Local $hUpdateBadge = GUICtrlCreateLabel("", 246, 9, 120, 20)
GUICtrlSetFont($hUpdateBadge, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hUpdateBadge, 0x0F0F0F)
GUICtrlSetBkColor($hUpdateBadge, 0xFFAA00)
GUICtrlSetState($hUpdateBadge, $GUI_HIDE)
; BrAiNPlay-Button in Titelleiste
Local $hBtnPlayer = GUICtrlCreateLabel("BP", 460, 8, 25, 20, $SS_CENTER)
GUICtrlSetFont($hBtnPlayer, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnPlayer, $CLR_TEXT)
GUICtrlSetBkColor($hBtnPlayer, $CLR_PANEL)
; Live-Button in Titelleiste
Local $hBtnLive = GUICtrlCreateLabel(" LIVE ", 450, 8, 48, 20)
GUICtrlSetFont($hBtnLive, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnLive, $CLR_TEXT)
GUICtrlSetBkColor($hBtnLive, 0x660000)
GUICtrlSetState($hBtnLive, $GUI_HIDE)
;
Local $hBtnMin = GUICtrlCreateLabel(ChrW(8211), 500, 8, 24, 22)
GUICtrlSetFont($hBtnMin, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnMin, $CLR_MUTED)
GUICtrlSetBkColor($hBtnMin, $CLR_PANEL)
;
Local $hClose = GUICtrlCreateLabel("x", 530, 8, 24, 22)
GUICtrlSetFont($hClose, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hClose, $CLR_MUTED)
GUICtrlSetBkColor($hClose, $CLR_PANEL)
; Trennlinie
Local $hLine = GUICtrlCreateLabel("", 0, 36, 560, 2)
GUICtrlSetBkColor($hLine, $CLR_ACCENT)
; ---- URL Eingabe ----
Local $hLabelURL = GUICtrlCreateLabel(_L("Data URL:"), 24, 58, 250, 18)
GUICtrlSetFont($hLabelURL, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLabelURL, $CLR_TEXT)
GUICtrlSetBkColor($hLabelURL, $CLR_BG)
Local $hInput = GUICtrlCreateEdit("", 24, 80, 512, 84, $ES_MULTILINE + $ES_AUTOVSCROLL + $WS_VSCROLL)
GUICtrlSetFont($hInput, 9, 400, 0, "Consolas")
GUICtrlSetColor($hInput, $CLR_TEXT)
GUICtrlSetBkColor($hInput, $CLR_INPUT)
; ---- Trennlinie ----
Local $hLine2 = GUICtrlCreateLabel("", 24, 182, 512, 1)
GUICtrlSetBkColor($hLine2, 0x2A2A2A)
; ---- Format Toggle ----
Local $hLabelFormat = GUICtrlCreateLabel(_L("Format:"), 24, 196, 60, 20)
GUICtrlSetFont($hLabelFormat, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLabelFormat, $CLR_MUTED)
GUICtrlSetBkColor($hLabelFormat, $CLR_BG)
Local $hToggleVideo = GUICtrlCreateLabel("Video(MP4)", 88, 191, 84, 26, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($hToggleVideo, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hToggleVideo, $CLR_TEXT)
GUICtrlSetBkColor($hToggleVideo, $CLR_ACCENT)
Local $hToggleMP3 = GUICtrlCreateLabel("Audio(MP3)", 176, 191, 84, 26, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($hToggleMP3, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hToggleMP3, $CLR_MUTED)
GUICtrlSetBkColor($hToggleMP3, 0x222222)
; ---- Playlist Toggle ----
Local $hLabelPlaylist = GUICtrlCreateLabel(_L("Mode:"), 24, 228, 60, 20)
GUICtrlSetFont($hLabelPlaylist, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLabelPlaylist, $CLR_MUTED)
GUICtrlSetBkColor($hLabelPlaylist, $CLR_BG)
Local $hToggleSingle = GUICtrlCreateLabel(_L("Single"), 88, 223, 84, 26, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($hToggleSingle, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hToggleSingle, $CLR_TEXT)
GUICtrlSetBkColor($hToggleSingle, $CLR_ACCENT)
Local $hTogglePlaylist = GUICtrlCreateLabel(_L("Multi"), 176, 223, 84, 26, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($hTogglePlaylist, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hTogglePlaylist, $CLR_MUTED)
GUICtrlSetBkColor($hTogglePlaylist, 0x222222)
Local $hToggleLive = GUICtrlCreateLabel(_L("Live"), 264, 223, 84, 26, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($hToggleLive, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hToggleLive, $CLR_MUTED)
GUICtrlSetBkColor($hToggleLive, 0x222222)
; ---- Buttons ----
; Start/Stop button = progress bar: $hProgBG (track, carries the button colour) + $hProgBar (fill) + $hBtnDownload (text on top, transparent)
Local $hProgBG = GUICtrlCreateLabel("", 24, $PROG_Y, 512, $PROG_H)
GUICtrlSetBkColor($hProgBG, 0x00AA44)
Local $hProgBar = GUICtrlCreateLabel("", 24, $PROG_Y, 0, $PROG_H)
GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
Local $hBtnDownload = GUICtrlCreateLabel(_L("Start"), 24, $PROG_Y, 512, $PROG_H, BitOR($SS_CENTER, $SS_CENTERIMAGE))
GUICtrlSetFont($hBtnDownload, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnDownload, $CLR_TEXT)
GUICtrlSetBkColor($hBtnDownload, $GUI_BKCOLOR_TRANSPARENT)
Local $hBtnPaste = GUICtrlCreateButton("PasteStart", 348, 266, 110, 38)
GUICtrlSetFont($hBtnPaste, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnPaste, $CLR_TEXT)
GUICtrlSetBkColor($hBtnPaste, 0x1E3A1E)
GUICtrlSetState($hBtnPaste, $GUI_HIDE) ; ersetzt durch Clipboard-Watcher
; ---- Fortschritts-Bereich ----
Local $hLine3 = GUICtrlCreateLabel("", 24, 318, 512, 1)
GUICtrlSetBkColor($hLine3, 0x2A2A2A)
Local $hProgLabel = GUICtrlCreateLabel(_L("Ready."), 24, 326, 512, 32, $SS_NOPREFIX) ; 2 lines: error messages fit
GUICtrlSetFont($hProgLabel, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hProgLabel, $CLR_MUTED)
GUICtrlSetBkColor($hProgLabel, $CLR_BG)
Local $hProgPct = GUICtrlCreateLabel("", 490, 326, 46, 16)
GUICtrlSetFont($hProgPct, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hProgPct, $CLR_ACCENT)
GUICtrlSetBkColor($hProgPct, $CLR_BG)
GUICtrlSetState($hProgPct, $GUI_HIDE) ; not shown any more - the % is in the Start/Stop button
; (the old progress bar below the text is gone - the Start/Stop button above is the bar now)
; ---- Statuszeile ----
Local $hStatus = GUICtrlCreateLabel(_L("Ready."), 0, 492, 560, 32)
GUICtrlSetFont($hStatus, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hStatus, $CLR_MUTED)
GUICtrlSetBkColor($hStatus, $CLR_PANEL)
GUICtrlSetStyle($hStatus, $SS_CENTER)
; ---- Play-Bereich ----
Local $hLine4 = GUICtrlCreateLabel("", 24, 386, 512, 1)
GUICtrlSetBkColor($hLine4, 0x2A2A2A)
Local $hBtnPlay = GUICtrlCreateLabel(_L("> Play last File"), 24, 398, 242, 36)
GUICtrlSetFont($hBtnPlay, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnPlay, $CLR_TEXT)
GUICtrlSetBkColor($hBtnPlay, 0x1A3A1A)
Local $hBtnFolder = GUICtrlCreateLabel(_L("[>] View Downloads"), 278, 398, 258, 36)
GUICtrlSetFont($hBtnFolder, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnFolder, $CLR_MUTED)
GUICtrlSetBkColor($hBtnFolder, 0x1A1A2A)
Local $hPlayLabel = GUICtrlCreateLabel(_L("No download completed yet."), 24, 440, 512, 16)
GUICtrlSetFont($hPlayLabel, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hPlayLabel, $CLR_MUTED)
GUICtrlSetBkColor($hPlayLabel, $CLR_BG)
; ============================================================
; ---- LIVE VIEW Controls (anfangs versteckt) ----
; ============================================================
; Roter Balken oben mit LIVE-Schriftzug
Local $hLiveBanner = GUICtrlCreateLabel("", 0, 38, 560, 40)
GUICtrlSetBkColor($hLiveBanner, 0x880000)
GUICtrlSetState($hLiveBanner, $GUI_HIDE)
Local $hLiveTitle = GUICtrlCreateLabel(">> LIVE VIEW", 20, 47, 300, 22)
GUICtrlSetFont($hLiveTitle, 11, 800, 0, "Segoe UI")
GUICtrlSetColor($hLiveTitle, $CLR_TEXT)
GUICtrlSetBkColor($hLiveTitle, 0x880000)
GUICtrlSetState($hLiveTitle, $GUI_HIDE)
; URL Input
Local $hLiveLabelURL = GUICtrlCreateLabel("URL:", 24, 94, 60, 18)
GUICtrlSetFont($hLiveLabelURL, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLiveLabelURL, $CLR_MUTED)
GUICtrlSetBkColor($hLiveLabelURL, $CLR_BG)
GUICtrlSetState($hLiveLabelURL, $GUI_HIDE)
Local $hLiveInput = GUICtrlCreateEdit("", 24, 114, 512, 48, $ES_MULTILINE + $ES_AUTOVSCROLL + $WS_VSCROLL)
GUICtrlSetFont($hLiveInput, 9, 400, 0, "Consolas")
GUICtrlSetColor($hLiveInput, $CLR_TEXT)
GUICtrlSetBkColor($hLiveInput, $CLR_INPUT)
GUICtrlSetState($hLiveInput, $GUI_HIDE)
; Info-Text
Local $hLiveInfo = GUICtrlCreateLabel("Opens _watch_live.mp4 in your player while downloading.  File stays in downloads folder.", 24, 172, 512, 16)
GUICtrlSetFont($hLiveInfo, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hLiveInfo, $CLR_MUTED)
GUICtrlSetBkColor($hLiveInfo, $CLR_BG)
GUICtrlSetState($hLiveInfo, $GUI_HIDE)
; Start/Stop Button
Local $hLiveBtnStart = GUICtrlCreateButton("Start Live", 24, 200, 250, 44)
GUICtrlSetFont($hLiveBtnStart, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hLiveBtnStart, $CLR_TEXT)
_BtnBk($hLiveBtnStart, 0x880000)
GUICtrlSetState($hLiveBtnStart, $GUI_HIDE)
; Paste+Start Button
Local $hLiveBtnPaste = GUICtrlCreateButton("PasteStart", 286, 200, 250, 44)
GUICtrlSetFont($hLiveBtnPaste, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hLiveBtnPaste, $CLR_TEXT)
GUICtrlSetBkColor($hLiveBtnPaste, 0x1E2A1E)
GUICtrlSetState($hLiveBtnPaste, $GUI_HIDE)
; Trennlinie
Local $hLiveLine = GUICtrlCreateLabel("", 24, 258, 512, 1)
GUICtrlSetBkColor($hLiveLine, 0x2A2A2A)
GUICtrlSetState($hLiveLine, $GUI_HIDE)
; Fortschritts-Label
Local $hLiveProgLabel = GUICtrlCreateLabel(_L("Ready."), 24, 268, 460, 16)
GUICtrlSetFont($hLiveProgLabel, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hLiveProgLabel, $CLR_MUTED)
GUICtrlSetBkColor($hLiveProgLabel, $CLR_BG)
GUICtrlSetState($hLiveProgLabel, $GUI_HIDE)
Local $hLiveProgSize = GUICtrlCreateLabel("", 490, 268, 46, 16)
GUICtrlSetFont($hLiveProgSize, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hLiveProgSize, 0x0088FF)
GUICtrlSetBkColor($hLiveProgSize, $CLR_BG)
GUICtrlSetState($hLiveProgSize, $GUI_HIDE)
; Fortschrittsbalken (pulsierend)
Local $hLiveProgBG = GUICtrlCreateLabel("", 24, 290, 512, 10)
GUICtrlSetBkColor($hLiveProgBG, 0x222222)
GUICtrlSetState($hLiveProgBG, $GUI_HIDE)
Local $hLiveProgBar = GUICtrlCreateLabel("", 24, 290, 0, 10)
GUICtrlSetBkColor($hLiveProgBar, 0x0088FF)
GUICtrlSetState($hLiveProgBar, $GUI_HIDE)
; ============================================================
; ---- BrAiNPlay test integration --------------------------------
; Same MultiDL window/style, native MCI first + WMP video fallback.
; ============================================================
Global Const $BP_BG = $CLR_BG, $BP_PNL = $CLR_PANEL, $BP_DIM = 0x2A2A2A, $BP_OFF = $CLR_MUTED, $BP_ACC = $CLR_ACCENT, $BP_TXT = $CLR_TEXT, $BP_N = 46, $BP_WY = 116, $BP_WA = 58
Global Const $BP_VX = 90, $BP_VW = 140, $BP_BX = 325, $BP_BW = 130, $BP_NV = 14, $BP_NB = 13
Global $BP_sApp = @AppDataDir & "\BrAiNPlay", $BP_sIni = $BP_sApp & "\brainplay.ini", $BP_sLast = $BP_sApp & "\last.m3u"
DirCreate($BP_sApp)
Global $BP_aPl[0], $BP_aLn[0], $BP_iCur = -1, $BP_iLen = 0, $BP_tCmd = 0, $BP_iOff = 0, $BP_tRun = 0, $BP_tStart = 0, $BP_fFixed = False, $BP_sTmp = @TempDir & "\BrAiNPlay_clean.mp3", $BP_fPlay = False, $BP_fPause = False, $BP_iLit = -1, $BP_aSeg[$BP_N], $BP_sNow = ""
Global $BP_fShuf = (IniRead($BP_sIni, "player", "shuf", "0") = "1"), $BP_fLoop = (IniRead($BP_sIni, "player", "loop", "0") = "1")
Global $BP_aBR = StringSplit("0|32|40|48|56|64|80|96|112|128|160|192|224|256|320", "|", 2), $BP_aSR[3] = [44100, 48000, 32000]
Global $BP_iVol = _Min(_Max(Int(IniRead($BP_sIni, "player", "vol", 80)), 0), 100), $BP_iBal = _Min(_Max(Int(IniRead($BP_sIni, "player", "bal", 0)), -100), 100)
Global $BP_iPre = 80, $BP_iDrag = 0, $BP_iErr = 0, $BP_iHov = 0, $BP_aV[$BP_NV], $BP_aB[$BP_NB]
Global $BP_sExt = "mp3|wav|wma|mp4|m4v|avi|wmv|mpg|mpeg|mov|mkv|webm|vob|m2ts|ts", $BP_sVid = "mp4|m4v|avi|wmv|mpg|mpeg|mov|mkv|webm|vob|m2ts|ts"
Global $BP_fVid = False, $BP_fVidOn = (IniRead($BP_sIni, "player", "video", "1") = "1"), $BP_fTray = False, $BP_iVSz = 0, $BP_fEmb = False, $BP_iWSt = -1
Global $BP_iWw = Int(IniRead($BP_sIni, "video", "dockw", 640)), $BP_iWh = Int(IniRead($BP_sIni, "video", "dockh", 360))
If $BP_iWw < 320 Or $BP_iWh < 180 Then
	$BP_iWw = 640
	$BP_iWh = 360
EndIf
Global $BP_iFFVol = -1, $BP_iFFBal = 0, $BP_tFFApply = 0 ; ffplay: volume/balance it was started with + time of the last change
Global $BP_fQuit = False, $BP_hVid = 0, $BP_fFull = (IniRead($BP_sIni, "player", "full", "1") = "1"), $BP_fVidShown = False, $BP_sPos = "", $BP_sWin = "", $BP_iSty = 0, $BP_iMon = 0, $BP_fWFS = False, $BP_fClick = (IniRead($BP_sIni, "video", "clickmode", "1") = "1"), $BP_tChg = 0, $BP_bDown = False, $BP_tPoll = 0
Global $BP_iZoom = 100, $BP_tNote = 0, $BP_hOsd = 0, $BP_lblOsd = 0, $BP_tOsd = 0, $BP_iOsdMs = 3000, $BP_fWK = False
Global $BP_fCurOn = True, $BP_iMx = -1, $BP_iMy = -1, $BP_tMouse = 0, $BP_fAwake = False
Global $BP_iFill = 0, $BP_iFillLog = 0, $BP_fMK = False, $BP_fQDone = False, $BP_tMK = 0, $BP_tMKp = 0
Global $BP_oWMP = 0, $BP_idWMP = 0, $BP_fWmp = False, $BP_iWInit = 0
Global $BP_oComErr = ObjEvent("AutoIt.Error", "BP_Err") ; keep COM handler alive under Wine
Global $BP_fWine = _IsWine(), $BP_fNoShell = False
If $BP_fWine Then $BP_fNoShell = True
BP_Log("start | " & ($BP_fWine ? "WINE | " : "") & "AutoIt " & @AutoItVersion & (@AutoItX64 ? " x64" : " x86") & " | OS " & @OSVersion & " " & @OSArch)
$BP_hMain = $hGUI
$BP_fTray = False
Opt("TrayMenuMode", 1) ; no default tray menu
Opt("TrayOnEventMode", 1)
TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "BP_FromTray") ; single click on the tray icon restores the window
OnAutoItExitRegister("BP_Quit")
; Embedded BrAiNPlay controls, styled like MultiDL.
Global $BP_bTV = BP_B(_L("VIDEO ON"), 452, 48, 84, 24, $BP_TXT, 9)
GUICtrlSetTip($BP_bTV, _L("Show / hide the video   (V = video on/off, F = fullscreen / window)"))
Global $BP_lblNow = GUICtrlCreateLabel(_L("stopped"), 24, 54, 424, 20)
GUICtrlSetColor($BP_lblNow, $BP_TXT)
GUICtrlSetFont($BP_lblNow, 9, 600, 0, "Segoe UI")
Global $BP_lblTime = GUICtrlCreateLabel("00:00 / --:--", 24, 156, 512, 20, $SS_CENTER)
GUICtrlSetColor($BP_lblTime, $BP_ACC)
GUICtrlSetFont($BP_lblTime, 10, 700, 0, "Segoe UI")
Local $bpH
For $i = 0 To $BP_N - 1
	$bpH = BP_Def($i)
	$BP_aSeg[$i] = GUICtrlCreateLabel("", BP_SegX($i), $BP_WY - Int($bpH / 2), 7, $bpH)
	GUICtrlSetBkColor($BP_aSeg[$i], $BP_DIM)
Next
Global $BP_bPrev = BP_B("|<", 24, 184, 70, 36, $BP_TXT, 9)
; play = U+25BA (in every Windows/Wine font); the old U+25B6 needs "Segoe UI Symbol" and shows as a box under Wine
Global $BP_bPlay = BP_B(ChrW(9658), 100, 184, 100, 36, $BP_TXT, 11)
Global $BP_bStop = BP_B("■", 206, 184, 70, 36, $BP_TXT, 10)
Global $BP_bNext = BP_B(">|", 282, 184, 70, 36, $BP_TXT, 9)
Global $BP_bShuf = BP_B(_L("SHUF"), 358, 184, 86, 36, $BP_TXT, 8)
Global $BP_bLoop = BP_B(_L("LOOP"), 450, 184, 86, 36, $BP_TXT, 8)
GUICtrlSetColor($BP_bShuf, $BP_fShuf ? $BP_ACC : $BP_OFF) ; restore the saved state colors
GUICtrlSetColor($BP_bLoop, $BP_fLoop ? $BP_ACC : $BP_OFF)
Global $BP_lblVol = GUICtrlCreateLabel(_L("VOL"), 24, 230, 60, 20, $SS_CENTERIMAGE)
GUICtrlSetColor($BP_lblVol, $BP_TXT)
Global $BP_lblBal = GUICtrlCreateLabel("BAL C", 250, 230, 70, 20, $SS_CENTERIMAGE)
GUICtrlSetColor($BP_lblBal, $BP_TXT)
For $i = 0 To $BP_NV - 1
	$bpH = 6 + $i
	$BP_aV[$i] = GUICtrlCreateLabel("", $BP_VX + $i * 10, 252 - $bpH, 8, $bpH)
Next
For $i = 0 To $BP_NB - 1
	$bpH = ($i = 6) ? 22 : 12
	$BP_aB[$i] = GUICtrlCreateLabel("", $BP_BX + $i * 10, 241 - Int($bpH / 2), 8, $bpH)
Next
Global $BP_bPL = BP_B("PLAYLIST", 24, 266, 512, 22, $BP_TXT, 8)
GUICtrlSetState($BP_bPL, $GUI_DROPACCEPTED)
Global $BP_lst = GUICtrlCreateList("", 24, 294, 512, 160, BitOR($LBS_NOTIFY, $WS_VSCROLL))
GUICtrlSetBkColor($BP_lst, $BP_PNL)
GUICtrlSetColor($BP_lst, $BP_TXT)
GUICtrlSetState($BP_lst, $GUI_DROPACCEPTED)
Global $BP_bAddFile = BP_B(_L("+ FILES"), 24, 462, 80, 34, $BP_TXT, 8)
Global $BP_bAddD = BP_B(_L("+ FOLDER"), 108, 462, 80, 34, $BP_TXT, 8)
Global $BP_bDel = BP_B(_L("REMOVE"), 192, 462, 80, 34, $BP_TXT, 8)
Global $BP_bClr = BP_B(_L("CLEAR"), 276, 462, 80, 34, $BP_TXT, 8)
Global $BP_bSave = BP_B(_L("SAVE"), 360, 462, 80, 34, $BP_TXT, 8)
Global $BP_bLoad = BP_B(_L("LOAD"), 444, 462, 92, 34, $BP_TXT, 8)
; Current BrAiNPlay keyboard map, via dummies so the MultiDL event loop stays in control.
Global $BP_kPlay = GUICtrlCreateDummy(), $BP_kStop = GUICtrlCreateDummy(), $BP_kNext = GUICtrlCreateDummy(), $BP_kPrev = GUICtrlCreateDummy()
Global $BP_kBack = GUICtrlCreateDummy(), $BP_kFwd = GUICtrlCreateDummy(), $BP_kVU = GUICtrlCreateDummy(), $BP_kVD = GUICtrlCreateDummy()
Global $BP_kMute = GUICtrlCreateDummy(), $BP_kDel = GUICtrlCreateDummy(), $BP_kTV = GUICtrlCreateDummy(), $BP_kFull = GUICtrlCreateDummy()
Global $BP_kZI = GUICtrlCreateDummy(), $BP_kZO = GUICtrlCreateDummy()
Global $BP_kZ0 = GUICtrlCreateDummy(), $BP_kAud = GUICtrlCreateDummy(), $BP_kMon = GUICtrlCreateDummy()
Global $BP_aK[19][2] = [["{SPACE}", $BP_kPlay], ["s", $BP_kStop], ["n", $BP_kNext], ["p", $BP_kPrev], ["{LEFT}", $BP_kBack], ["{RIGHT}", $BP_kFwd], ["^{UP}", $BP_kVU], ["^{DOWN}", $BP_kVD], ["m", $BP_kMute], ["{DEL}", $BP_kDel], ["v", $BP_kTV], ["f", $BP_kFull], ["{+}", $BP_kZI], ["{NUMPADADD}", $BP_kZI], ["-", $BP_kZO], ["{NUMPADSUB}", $BP_kZO], ["0", $BP_kZ0], ["a", $BP_kAud], ["d", $BP_kMon]]
Func BP_KeyDown($vk)
	Local $r = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", $vk)
	Return (Not @error) And BitAND($r[0], 0x8000) <> 0
EndFunc   ;==>BP_KeyDown
Func BP_MkPlay() ; play/pause media key, ignoring auto-repeat while the key is held
	Local $dt = TimerDiff($BP_tMKp)
	$BP_tMKp = TimerInit()
	If $dt >= 400 Then BP_PlayPause()
EndFunc   ;==>BP_MkPlay
Func BP_MkStop()
	Local $dt = TimerDiff($BP_tMKp)
	$BP_tMKp = TimerInit()
	If $dt >= 400 Then BP_Stop()
EndFunc   ;==>BP_MkStop
Func BP_MkNext() ; media key "next": short press = next track, hold = fast forward
	BP_MkKey(1)
EndFunc   ;==>BP_MkNext
Func BP_MkPrev() ; media key "previous": short press = previous track, hold = rewind
	BP_MkKey(-1)
EndFunc   ;==>BP_MkPrev
Func BP_MkKey($dir)
	Local $dt = TimerDiff($BP_tMK), $vk = ($dir > 0) ? 0xB0 : 0xB1, $t = TimerInit(), $bHold = False
	$BP_tMK = TimerInit()
	If $dt < 400 Then Return ; auto-repeat of a key that is being held / rested on -> ignore
	While BP_KeyDown($vk)
		If TimerDiff($t) > 400 Then
			$bHold = True
			ExitLoop
		EndIf
		Sleep(15)
	WEnd
	If Not $bHold Then
		BP_Next($dir) ; short press
	Else
		While BP_KeyDown($vk) ; held: seek 5 s every 200 ms
			BP_Skip($dir * 5)
			$BP_tMK = TimerInit()
			Sleep(200)
		WEnd
	EndIf
	$BP_tMK = TimerInit() ; repeats that queued up meanwhile are ignored
EndFunc   ;==>BP_MkKey
Func BP_MediaKeys($on) ; multimedia keys (play/pause, next, previous, stop) - only registered while the player is in use, so other players keep their keys
	If $on = $BP_fMK Then Return
	$BP_fMK = $on
	Local $k = StringSplit("{MEDIA_PLAY_PAUSE}|{MEDIA_NEXT}|{MEDIA_PREV}|{MEDIA_STOP}", "|", 2)
	Local $f = StringSplit("BP_MkPlay|BP_MkNext|BP_MkPrev|BP_MkStop", "|", 2)
	For $i = 0 To UBound($k) - 1
		If $on Then
			HotKeySet($k[$i], $f[$i])
		Else
			HotKeySet($k[$i])
		EndIf
	Next
EndFunc   ;==>BP_MediaKeys
Func BP_Keys($on) ; player keys only active in player mode, otherwise they eat letters typed in the URL field
	BP_MediaKeys($on Or $BP_fPlay) ; (music keeps playing after leaving the player view -> keep the media keys then)
	If $on Then
		GUISetAccelerators($BP_aK, $hGUI)
	Else
		GUISetAccelerators(0, $hGUI)
	EndIf
EndFunc   ;==>BP_Keys
Global $BP_aControls[19] = [$BP_bTV, $BP_lblNow, $BP_lblTime, $BP_bPrev, $BP_bPlay, $BP_bStop, $BP_bNext, $BP_bShuf, $BP_bLoop, $BP_lblVol, $BP_lblBal, $BP_bPL, $BP_lst, $BP_bAddD, $BP_bDel, $BP_bClr, $BP_bSave, $BP_bLoad, $BP_bAddFile]
; OSD window used by current BrAiNPlay.
$BP_hOsd = GUICreate("", 400, 40, 0, 0, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW, $WS_EX_NOACTIVATE), $hGUI)
GUISetBkColor($BP_BG, $BP_hOsd)
$BP_lblOsd = GUICtrlCreateLabel("", 12, 6, 376, 28)
GUICtrlSetColor($BP_lblOsd, $BP_TXT)
GUICtrlSetFont($BP_lblOsd, 15, 700, 0, "Segoe UI")
GUICtrlSetResizing($BP_lblOsd, $GUI_DOCKALL)
WinSetTrans($BP_hOsd, "", 225)
GUISwitch($hGUI)
Func BP_SetControls($state)
	For $bpC In $BP_aControls
		GUICtrlSetState($bpC, $state)
	Next
	For $bpI = 0 To $BP_N - 1
		GUICtrlSetState($BP_aSeg[$bpI], $state)
	Next
	For $bpI = 0 To $BP_NV - 1
		GUICtrlSetState($BP_aV[$bpI], $state)
	Next
	For $bpI = 0 To $BP_NB - 1
		GUICtrlSetState($BP_aB[$bpI], $state)
	Next
EndFunc   ;==>BP_SetControls
$BP_hVid = GUICreate("MultiDL BrAiNPlay Video", $BP_iWw, $BP_iWh, -1, -1, BitOR($WS_POPUP, $WS_CLIPCHILDREN), $WS_EX_NOACTIVATE, $hGUI)
GUISetBkColor(0x000000, $BP_hVid)
GUIRegisterMsg($WM_CLOSE, "BP_WMClose")
If _ShowMsgId() Then GUIRegisterMsg(_ShowMsgId(), "_OnShowMe")
GUISwitch($hGUI)
BP_SetControls($GUI_HIDE)
BP_Apply()
BP_PLText()
; ---- Optionen-Fenster (wird bei Bedarf eingeblendet) ----
$g_hOptGUI = GUICreate(_L("MultiDL Options"), 280, 456, -1, -1, $WS_CAPTION + $WS_SYSMENU, -1, $hGUI)
Local $hOptTitle = GUICtrlCreateLabel(_L("Link-Detection"), 16, 14, 248, 22)
$g_hOptClip = GUICtrlCreateCheckbox(_L("Check for Links in Clipboard."), 18, 44, 250, 22)
$g_hOptDomain = GUICtrlCreateCheckbox(_L("Resolve Links without http(s)"), 18, 72, 250, 22)
$g_hOptAuto = GUICtrlCreateCheckbox(_L("Automatic-Mode"), 18, 100, 250, 22)
If $g_bClipWatch Then GUICtrlSetState($g_hOptClip, $GUI_CHECKED)
If $g_bDomainLinks Then GUICtrlSetState($g_hOptDomain, $GUI_CHECKED)
If $g_bAutoStart Then GUICtrlSetState($g_hOptAuto, $GUI_CHECKED)
Local $hOptTitleP = GUICtrlCreateLabel(_L("Player"), 16, 138, 248, 22)
$g_hOptBP = GUICtrlCreateCheckbox(_L("Use internal player (BrAiNPlay)"), 18, 164, 250, 22)
If $g_bUseBP Then GUICtrlSetState($g_hOptBP, $GUI_CHECKED)
Local $hOptTitle2 = GUICtrlCreateLabel(_L("Tools"), 16, 204, 248, 22)
$g_hOptConsole = GUICtrlCreateButton(_ConsoleBtnText(), 18, 230, 244, 30)
$g_hOptUpdate = GUICtrlCreateButton(_L("Update all tools"), 18, 266, 244, 30)
Local $hOptTitle3 = GUICtrlCreateLabel(_L("Program"), 16, 306, 248, 22)
$g_hOptMulti = GUICtrlCreateCheckbox(_L("Allow multiple instances (Multi-Run)"), 18, 332, 250, 22)
If $g_bMultiInst Then GUICtrlSetState($g_hOptMulti, $GUI_CHECKED)
$g_hOptLang = GUICtrlCreateButton(_LangBtnText(), 18, 362, 244, 30)
$g_hOptClose = GUICtrlCreateButton(_L("CLOSE"), 92, 410, 95, 28)
GUICtrlSetState($g_hOptGUI, $GUI_HIDE)
If Not $g_bUseBP Then GUICtrlSetState($hBtnPlayer, $GUI_HIDE) ; internal player disabled -> no BP button
; ---- Fenster anzeigen ----
GUISetState(@SW_SHOW, $hGUI)
WinActivate($hGUI)
If $g_bClipWatch Then $g_sLastClipboard = ClipGet() ; vorhandenen Clipboard-Inhalt nicht ungefragt auto-starten
_CheckForUpdate($hUpdateBadge)
_ModeStatus($hStatus)
Local $tBPUI = TimerInit()
Local $tHov = TimerInit(), $bTitleHov = False
Local $tAct = TimerInit(), $bAct = False ; make sure the window really has the focus after start (else the first click is lost)
; ---- Hauptschleife ----
Local $bLiveMode = False
; Pulse fuer Live-Balken
Local $iPulse = 0, $iPulseDir = 1
Local $bLPrev = False, $bEdgePend = False, $tEdge = 0, $aEdge[2] = [0, 0] ; title-bar click safety net (see loop head)
While 1
	Local $aMsg = GUIGetMsg(1)
	Local $iMsg = $aMsg[0]
	If $BP_fQuit Then ExitLoop
	If $g_bShowReq Then ; a second start of MultiDL asked us to show the window
		$g_bShowReq = False
		If $BP_fTray Then
			BP_FromTray()
		Else
			GUISetState(@SW_SHOW, $hGUI)
			GUISetState(@SW_RESTORE, $hGUI)
			WinActivate($hGUI)
		EndIf
	EndIf
	; ---- title-bar click safety net: AutoIt loses the PRIMARYDOWN of a click while the window is inactive or the loop is busy
	; -> watch the physical left button too; if no PRIMARYDOWN shows up shortly after a press, handle that click ourselves ----
	Local $bSynth = False
	Local $aLB = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 0x01)
	Local $bLNow = (IsArray($aLB) And BitAND($aLB[0], 0x8000) <> 0)
	If $bLNow And Not $bLPrev Then
		$aEdge = MouseGetPos()
		$tEdge = TimerInit()
		$bEdgePend = True
	EndIf
	$bLPrev = $bLNow
	If $bEdgePend Then
		If TimerDiff($tEdge) > 500 Then
			$bEdgePend = False
		ElseIf TimerDiff($tEdge) > 100 And $iMsg = 0 Then
			$bEdgePend = False
			Local $aWP0 = WinGetPos($hGUI)
			If IsArray($aWP0) And Not $BP_fTray Then
				Local $iEX = $aEdge[0] - $aWP0[0], $iEY = $aEdge[1] - $aWP0[1]
				If $iEY >= 0 And $iEY < 36 And $iEX >= 0 And $iEX < 560 And _OverMainWin($aEdge) Then
					$bSynth = True
					$iMsg = $GUI_EVENT_PRIMARYDOWN
					$aMsg[1] = $hGUI
				EndIf
			EndIf
		EndIf
	EndIf
	If Not $bAct Then
		If WinActive($hGUI) Or TimerDiff($tAct) > 2000 Then
			$bAct = True
		Else
			WinActivate($hGUI)
		EndIf
	EndIf
	; ---- app name = options button: highlight on mouse over ----
	If TimerDiff($tHov) > 60 Then
		$tHov = TimerInit()
		Local $aHI = GUIGetCursorInfo($hGUI)
		Local $bH = False
		If IsArray($aHI) Then
			If $aHI[0] >= 20 And $aHI[0] <= 160 And $aHI[1] >= 0 And $aHI[1] <= 36 And Not $BP_fTray Then $bH = True
		EndIf
		If $bH <> $bTitleHov Then
			$bTitleHov = $bH
			GUICtrlSetColor($hTitleText, $bH ? $CLR_ACCENT : $CLR_TEXT)
		EndIf
	EndIf
	; ---- a file should be played in BrAiNPlay (Play last File and live view share this) ----
	If $g_sPlayReq <> "" Then
		Local $sPR = $g_sPlayReq
		$g_sPlayReq = ""
		If Not $BP_bPlayerMode Then
			$BP_bPlayerMode = True
			_ShowNormalControls($GUI_HIDE, $hLabelURL, $hInput, $hLine2, $hLabelFormat, $hToggleVideo, $hToggleMP3, $hLabelPlaylist, $hToggleSingle, $hTogglePlaylist, $hBtnDownload, $hBtnPaste, $hLine3, $hProgLabel, $hProgPct, $hProgBG, $hProgBar, $hLine4, $hBtnPlay, $hBtnFolder, $hPlayLabel, $hStatus, $hToggleLive)
			_ShowLiveControls($GUI_HIDE, $hLiveBanner, $hLiveTitle, $hLiveLabelURL, $hLiveInput, $hLiveInfo, $hLiveBtnStart, $hLiveBtnPaste, $hLiveLine, $hLiveProgLabel, $hLiveProgSize, $hLiveProgBG, $hLiveProgBar)
			BP_SetControls($GUI_SHOW)
			BP_Keys(True)
			BP_Apply()
			BP_PLText()
			BP_LoadDL(True)
			GUICtrlSetBkColor($hBtnPlayer, $CLR_ACCENT)
		EndIf
		Local $prFound = False
		For $prI = 0 To UBound($BP_aPl) - 1
			If StringLower($BP_aPl[$prI]) = StringLower($sPR) Then
				$prFound = True
				BP_Play($prI)
				ExitLoop
			EndIf
		Next
		If Not $prFound Then
			BP_Add($sPR)
			BP_Play(UBound($BP_aPl) - 1)
		EndIf
	EndIf
	; ---- player playlist follows the download folder (also while a download runs) ----
	If $BP_bPlayerMode And TimerDiff($g_tPLSync) > 3000 Then
		$g_tPLSync = TimerInit()
		BP_LoadDL()
	EndIf
	; ---- Fortschritt lesen wenn Download laeuft ----
	If $hDLProc <> 0 Then
		If $bLiveMode Then
			_ReadLiveProgress($hProgBar, $hProgLabel, $hProgPct, $hBtnDownload, $PROG_Y, $PROG_H, $hStatus)
		Else
			_ReadProgress($hProgBar, $hProgLabel, $hProgPct, $hStatus)
		EndIf
	EndIf
	; ---- embedded BrAiNPlay runtime ----
	If $BP_bPlayerMode And $BP_iDrag Then BP_Drag()
	If $BP_bPlayerMode Or $BP_fPlay Then ; the player keeps going (next track, video) while the download view is shown
		If $BP_fVidShown And TimerDiff($BP_tPoll) > 30 Then
			$BP_tPoll = TimerInit()
			BP_VidPoll()
		EndIf
		If $BP_fFF And $BP_pFF And TimerDiff($g_tFFKey) > 30 Then ; keys typed into the ffplay window (F / V)
			$g_tFFKey = TimerInit()
			BP_FFKeys()
		EndIf
		If TimerDiff($tBPUI) > 200 Then
			BP_Tick()
			$tBPUI = TimerInit()
		EndIf
	EndIf
	; ---- Zwischenablage überwachen (nicht blockierend) ----
	If $g_bClipWatch And ($g_bAutoStart Or Not $BP_bPlayerMode) And TimerDiff($g_tClipPoll) >= 450 Then
		$g_tClipPoll = TimerInit()
		Local $sClipNow = ClipGet()
		If Not @error And $sClipNow <> "" And $sClipNow <> $g_sLastClipboard Then
			$g_sLastClipboard = $sClipNow
			Local $sDetected = _DetectURL($sClipNow, $g_bDomainLinks)
			If $sDetected <> "" Then
				GUICtrlSetData($hInput, $sDetected)
				_RefreshInputLink($hInput)
				_UpdateStartAppearance($hBtnDownload, True)
				_SetStatus($hStatus, "Link detected in clipboard.", 0x4FC3F7)
				If $g_bAutoStart And $sDetected <> $g_sLastAutoURL And $hDLProc = 0 Then
					$g_sLastAutoURL = $sDetected
					Local $sAutoClean = _CleanURL($sDetected)
					If $bLiveMode Then
						_StartLive($sAutoClean, $hProgBar, $hProgLabel, $hProgPct, $hBtnDownload, $PROG_Y, $PROG_H)
					Else
						_StartDownload($sAutoClean, $hStatus, $hProgBar, $hProgLabel, $hProgPct)
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	; Start-Button-Farbe anhand des Eingabefelds aktualisieren
	If $hDLProc <> 0 Or $BP_bPlayerMode Then $g_iStartState = -1 ; Button wird anderswo umgefaerbt -> danach einmal neu setzen
	If Not $BP_bPlayerMode And $hDLProc = 0 Then _UpdateStartAppearance($hBtnDownload, _DetectURL(GUICtrlRead($hInput), $g_bDomainLinks) <> "")
	; Optionsfenster hat eigene Nachrichten
	If $aMsg[1] = $g_hOptGUI Then
		If $iMsg = $GUI_EVENT_CLOSE Or $iMsg = $g_hOptClose Then
			GUISetState(@SW_HIDE, $g_hOptGUI)
		ElseIf $iMsg = $g_hOptBP Then
			$g_bUseBP = (BitAND(GUICtrlRead($g_hOptBP), $GUI_CHECKED) = $GUI_CHECKED)
			IniWrite($CFG_FILE, "features", "use_brainplay", $g_bUseBP ? "1" : "0")
			GUICtrlSetState($hBtnPlayer, ($g_bUseBP Or $BP_bPlayerMode) ? $GUI_SHOW : $GUI_HIDE)
		ElseIf $iMsg = $g_hOptLang Then
			$g_sLang = ($g_sLang = "de") ? "en" : "de"
			IniWrite($CFG_FILE, "features", "language", $g_sLang)
			_ApplyLang()
		ElseIf $iMsg = $g_hOptMulti Then
			$g_bMultiInst = (BitAND(GUICtrlRead($g_hOptMulti), $GUI_CHECKED) = $GUI_CHECKED)
			IniWrite($CFG_FILE, "features", "multi_instance", $g_bMultiInst ? "1" : "0")
		ElseIf $iMsg = $g_hOptConsole Then
			$bShowCMD = Not $bShowCMD
			GUICtrlSetData($g_hOptConsole, _ConsoleBtnText())
		ElseIf $iMsg = $g_hOptUpdate Then
			If $hDLProc <> 0 Then
				MsgBox(48, "MultiDL", _L("Stop the download first!"), 0, $g_hOptGUI)
			ElseIf $BP_bPlayerMode Then
				MsgBox(48, "MultiDL", _L("Close the player first (BP button) - the update progress is shown in the download view."), 0, $g_hOptGUI)
			Else
				GUISetState(@SW_HIDE, $g_hOptGUI)
				_UpdateTools($hStatus, $hProgBar, $hProgLabel, $hProgPct)
			EndIf
		ElseIf $iMsg = $g_hOptClip Or $iMsg = $g_hOptDomain Or $iMsg = $g_hOptAuto Then
			$g_bClipWatch = (BitAND(GUICtrlRead($g_hOptClip), $GUI_CHECKED) = $GUI_CHECKED)
			$g_bDomainLinks = (BitAND(GUICtrlRead($g_hOptDomain), $GUI_CHECKED) = $GUI_CHECKED)
			$g_bAutoStart = (BitAND(GUICtrlRead($g_hOptAuto), $GUI_CHECKED) = $GUI_CHECKED)
			IniWrite($CFG_FILE, "features", "clipboard_watch", $g_bClipWatch ? "1" : "0")
			IniWrite($CFG_FILE, "features", "domain_links", $g_bDomainLinks ? "1" : "0")
			IniWrite($CFG_FILE, "features", "auto_start", $g_bAutoStart ? "1" : "0")
		EndIf
		ContinueLoop
	EndIf
	Select
		Case $iMsg = $GUI_EVENT_CLOSE
			; GUIGetMsg(1) returns the handle of the GUI that sent the close event.
			; Closing BrAiNPlay's separate video window must not close the main app.
			If _EscPressed() Then
				; AutoIt turns the Esc key into a close event - Esc must never close the app (only the X button does)
			ElseIf $aMsg[1] = $BP_hVid Then
				$BP_fVidOn = False
				BP_VidApply() ; hides the window + updates the VIDEO ON/OFF button (cursor, keep-awake, OSD, WMP fullscreen)
			ElseIf $aMsg[1] = $hGUI Then
				ExitLoop
			EndIf
		Case $iMsg = $GUI_EVENT_PRIMARYDOWN
			$bEdgePend = False ; this click is handled (not lost)
			$bLPrev = True
			If $BP_bPlayerMode And Not $bSynth Then
				Local $bpCInfo = GUIGetCursorInfo($hGUI)
				If IsArray($bpCInfo) Then
					If $bpCInfo[1] >= 76 And $bpCInfo[1] <= 152 And $bpCInfo[0] >= 20 And $bpCInfo[0] <= 540 Then
						BP_Seek(_Min(_Max(($bpCInfo[0] - 24) / 512, 0), 0.999))
					ElseIf $bpCInfo[1] >= 225 And $bpCInfo[1] <= 260 Then
						If $bpCInfo[0] >= $BP_VX - 6 And $bpCInfo[0] <= $BP_VX + $BP_VW + 6 Then $BP_iDrag = 1
						If $bpCInfo[0] >= $BP_BX - 6 And $bpCInfo[0] <= $BP_BX + $BP_BW + 6 Then $BP_iDrag = 2
					EndIf
				EndIf
			EndIf
			Local $aCursorPos = $bSynth ? $aEdge : MouseGetPos()
			Local $aWinPos = WinGetPos($hGUI)
			Local $iRelX = $aCursorPos[0] - $aWinPos[0]
			Local $iRelY = $aCursorPos[1] - $aWinPos[1]
			; X-Button
			If $iRelX >= 524 And $iRelX <= 559 And $iRelY >= 0 And $iRelY <= 36 Then
				ExitLoop
			EndIf
			;update badge
			If $iRelX >= 246 And $iRelX <= 366 And $iRelY >= 0 And $iRelY <= 36 And BitAND(GUICtrlGetState($hUpdateBadge), $GUI_SHOW) = $GUI_SHOW Then
				_SelfUpdate()
			EndIf
			; Minimize-Button
			If $iRelX >= 499 And $iRelX <= 523 And $iRelY >= 0 And $iRelY <= 36 Then BP_ToTray()
			; Optionen-Button
			If $iRelX >= 20 And $iRelX <= 160 And $iRelY >= 0 And $iRelY <= 36 Then
				GUICtrlSetState($g_hOptClip, $g_bClipWatch ? $GUI_CHECKED : $GUI_UNCHECKED)
				GUICtrlSetState($g_hOptDomain, $g_bDomainLinks ? $GUI_CHECKED : $GUI_UNCHECKED)
				GUICtrlSetState($g_hOptAuto, $g_bAutoStart ? $GUI_CHECKED : $GUI_UNCHECKED)
				GUICtrlSetData($g_hOptConsole, _ConsoleBtnText())
				GUICtrlSetState($g_hOptBP, $g_bUseBP ? $GUI_CHECKED : $GUI_UNCHECKED)
				GUICtrlSetState($g_hOptMulti, $g_bMultiInst ? $GUI_CHECKED : $GUI_UNCHECKED)
				GUISetState(@SW_SHOW, $g_hOptGUI)
			EndIf
			; PLAYER-Button
			If $iRelX >= 460 And $iRelX <= 485 And $iRelY >= 0 And $iRelY <= 36 And ($g_bUseBP Or $BP_bPlayerMode) Then
				$BP_bPlayerMode = Not $BP_bPlayerMode
				If $BP_bPlayerMode Then
					_ShowNormalControls($GUI_HIDE, $hLabelURL, $hInput, $hLine2, $hLabelFormat, $hToggleVideo, $hToggleMP3, $hLabelPlaylist, $hToggleSingle, $hTogglePlaylist, $hBtnDownload, $hBtnPaste, $hLine3, $hProgLabel, $hProgPct, $hProgBG, $hProgBar, $hLine4, $hBtnPlay, $hBtnFolder, $hPlayLabel, $hStatus, $hToggleLive)
					_ShowLiveControls($GUI_HIDE, $hLiveBanner, $hLiveTitle, $hLiveLabelURL, $hLiveInput, $hLiveInfo, $hLiveBtnStart, $hLiveBtnPaste, $hLiveLine, $hLiveProgLabel, $hLiveProgSize, $hLiveProgBG, $hLiveProgBar)
					BP_SetControls($GUI_SHOW)
					BP_Keys(True)
					BP_Apply()
					BP_PLText()
					BP_LoadDL(True)
					GUICtrlSetBkColor($hBtnPlayer, $CLR_ACCENT)
					BP_VidApply()
					If $sLastFile <> "" And FileExists($sLastFile) Then
						Local $bpFound = False
						For $bpI = 0 To UBound($BP_aPl) - 1
							If StringLower($BP_aPl[$bpI]) = StringLower($sLastFile) Then $bpFound = True
						Next
						If Not $bpFound Then BP_Add($sLastFile)
					EndIf
				Else
					BP_SetControls($GUI_HIDE)
					BP_Keys(False)
					BP_VidApply()
					GUICtrlSetBkColor($hBtnPlayer, 0x222222)
					If Not $g_bUseBP Then GUICtrlSetState($hBtnPlayer, $GUI_HIDE)
					_ShowNormalControls($GUI_SHOW, $hLabelURL, $hInput, $hLine2, $hLabelFormat, $hToggleVideo, $hToggleMP3, $hLabelPlaylist, $hToggleSingle, $hTogglePlaylist, $hBtnDownload, $hBtnPaste, $hLine3, $hProgLabel, $hProgPct, $hProgBG, $hProgBar, $hLine4, $hBtnPlay, $hBtnFolder, $hPlayLabel, $hStatus, $hToggleLive)
				EndIf
			EndIf
			; Nativer Windows-Drag nur auf wirklich freier Titelleiste.
			; Klickbereiche (Optionen/Titel, Update-Badge und rechte Buttons) bleiben ausgeschlossen.
			Local $bUpdateBadgeVisible = (BitAND(GUICtrlGetState($hUpdateBadge), $GUI_SHOW) = $GUI_SHOW)
			If $iRelY < 36 And ($bLNow Or Not $bSynth) And Not (($iRelX >= 20 And $iRelX <= 160) Or ($bUpdateBadgeVisible And $iRelX >= 246 And $iRelX <= 366) Or ($iRelX >= 450 And $iRelX <= 560)) Then
				; WM_NCLBUTTONDOWN erwartet die Bildschirmkoordinaten des Mauszeigers in lParam.
				Local $iDragLParam = BitOR(BitAND($aCursorPos[0], 0xFFFF), BitShift(BitAND($aCursorPos[1], 0xFFFF), -16))
				DllCall("user32.dll", "bool", "ReleaseCapture")
				DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hGUI, "uint", 0x00A1, "wparam", 2, "lparam", $iDragLParam) ; WM_NCLBUTTONDOWN / HTCAPTION
			EndIf
			; ---- embedded BrAiNPlay controls ----
		Case $iMsg = $BP_bPlay
			If $BP_bPlayerMode Then BP_PlayPause()
		Case $iMsg = $BP_bStop
			If $BP_bPlayerMode Then BP_Stop()
		Case $iMsg = $BP_bNext
			If $BP_bPlayerMode Then BP_Next(1)
		Case $iMsg = $BP_kPlay
			If $BP_bPlayerMode Then BP_PlayPause()
		Case $iMsg = $BP_kStop
			If $BP_bPlayerMode Then BP_Stop()
		Case $iMsg = $BP_kNext
			If $BP_bPlayerMode Then BP_Next(1)
		Case $iMsg = $BP_kPrev
			If $BP_bPlayerMode Then BP_Prev()
		Case $iMsg = $BP_kBack
			If $BP_bPlayerMode Then BP_Skip(-10)
		Case $iMsg = $BP_kFwd
			If $BP_bPlayerMode Then BP_Skip(10)
		Case $iMsg = $BP_kVU
			If $BP_bPlayerMode Then BP_Vol(5)
		Case $iMsg = $BP_kVD
			If $BP_bPlayerMode Then BP_Vol(-5)
		Case $iMsg = $BP_kMute
			If $BP_bPlayerMode Then BP_Mute()
		Case $iMsg = $BP_kDel
			If $BP_bPlayerMode Then BP_DelSel()
		Case $iMsg = $BP_kTV
			If $BP_bPlayerMode Then BP_ToggleVid()
		Case $iMsg = $BP_kFull
			If $BP_bPlayerMode Then BP_VidKey("f")
		Case $iMsg = $BP_kZI
			If $BP_bPlayerMode Then BP_Zoom(10)
		Case $iMsg = $BP_kZO
			If $BP_bPlayerMode Then BP_Zoom(-10)
		Case $iMsg = $BP_kZ0
			If $BP_bPlayerMode Then BP_Zoom(0)
		Case $iMsg = $BP_kAud
			If $BP_bPlayerMode Then BP_AudioTrack()
		Case $iMsg = $BP_kMon
			If $BP_bPlayerMode Then BP_NextMonitor()
		Case $iMsg = $BP_bTV
			If $BP_bPlayerMode Then BP_ToggleVid()
		Case $iMsg = $BP_bPrev
			If $BP_bPlayerMode Then BP_Prev()
		Case $iMsg = $BP_bShuf
			If $BP_bPlayerMode Then
				$BP_fShuf = Not $BP_fShuf
				GUICtrlSetColor($BP_bShuf, $BP_fShuf ? $BP_ACC : $BP_OFF)
			EndIf
		Case $iMsg = $BP_bLoop
			If $BP_bPlayerMode Then
				$BP_fLoop = Not $BP_fLoop
				GUICtrlSetColor($BP_bLoop, $BP_fLoop ? $BP_ACC : $BP_OFF)
			EndIf
		Case $iMsg = $BP_bAddFile
			If $BP_bPlayerMode Then
				Local $bpFiles = FileOpenDialog(_L("Add files"), "", "Media (*.mp3;*.wav;*.wma;*.mp4;*.m4v;*.avi;*.wmv;*.mpg;*.mpeg;*.mov;*.mkv;*.webm)", 5)
				If Not @error Then
					Local $bpA = StringSplit($bpFiles, "|", 2)
					If UBound($bpA) = 1 Then BP_Add($bpA[0])
					For $bpI = 1 To UBound($bpA) - 1
						BP_Add($bpA[0] & "\" & $bpA[$bpI])
					Next
				EndIf
			EndIf
		Case $iMsg = $BP_bAddD
			If $BP_bPlayerMode Then
				Local $bpDir = FileSelectFolder(_L("Add folder"), "")
				If Not @error Then BP_Add($bpDir)
			EndIf
		Case $iMsg = $BP_bDel
			If $BP_bPlayerMode Then BP_DelSel()
		Case $iMsg = $BP_bClr
			If $BP_bPlayerMode Then
				BP_Clear()
				$g_bPLManual = False ; empty list: new downloads show up again
			EndIf
		Case $iMsg = $BP_bSave
			If $BP_bPlayerMode And UBound($BP_aPl) Then
				Local $bpSave = FileSaveDialog(_L("Save playlist"), "", "Playlist (*.m3u)", 16, "playlist.m3u")
				If Not @error Then
					If Not StringRegExp($bpSave, "(?i)\.m3u8?$") Then $bpSave &= ".m3u"
					BP_SaveList($bpSave)
				EndIf
			EndIf
		Case $iMsg = $BP_bLoad
			If $BP_bPlayerMode Then
				Local $bpLoad = FileOpenDialog(_L("Load playlist"), "", "Playlist (*.m3u;*.m3u8)", 1)
				If Not @error Then
					BP_Clear()
					BP_LoadList($bpLoad)
					$g_bPLManual = True ; loaded by hand: no automatic additions any more
				EndIf
			EndIf
		Case $iMsg = $BP_lst
			If $BP_bPlayerMode Then
				Local $bpSel = GUICtrlSendMsg($BP_lst, $LB_GETCURSEL, 0, 0)
				If $bpSel >= 0 And ($bpSel <> $BP_iCur Or Not $BP_fPlay) Then BP_Play($bpSel)
			EndIf
			; ---- Live Start/Stop ----
		Case $iMsg = $hLiveBtnStart
			If $hDLProc <> 0 Then
				ProcessClose($hDLProc)
				$hDLProc = 0
				Local $oProcs = ProcessList()
				For $p = 1 To $oProcs[0][0]
					Select
						Case StringInStr($oProcs[$p][0], "yt-dlp")
							ProcessClose($oProcs[$p][1])
						Case StringInStr($oProcs[$p][0], "ffmpeg")
							ProcessClose($oProcs[$p][1])
					EndSelect
				Next
				GUICtrlSetPos($hLiveProgBar, 24, 290, 0, 10)
				GUICtrlSetData($hLiveProgLabel, _L("Stopped."))
				GUICtrlSetData($hLiveProgSize, "")
				GUICtrlSetData($hLiveBtnStart, _L("Start"))
				_BtnBk($hLiveBtnStart, 0x880000)
				$BP_bPlayerOpened = False
				BP_DropLive()
			Else
				Local $sRaw = GUICtrlRead($hLiveInput)
				$sRaw = StringStripWS($sRaw, 3)
				If $sRaw = "" Then
					GUICtrlSetData($hLiveProgLabel, _L("No URL entered."))
				Else
					_StartLive($sRaw, $hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart)
				EndIf
			EndIf
			; ---- Live PasteStart ----
		Case $iMsg = $hLiveBtnPaste
			If $hDLProc <> 0 Then
				GUICtrlSetData($hLiveProgLabel, _L("Stop first!"))
			Else
				Local $sClip = ClipGet()
				If $sClip = "" Then
					GUICtrlSetData($hLiveProgLabel, _L("Clipboard empty."))
				Else
					GUICtrlSetData($hLiveInput, $sClip)
					_StartLive($sClip, $hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart)
				EndIf
			EndIf
			; Format: Video / Audio / Live (one selection)
		Case $iMsg = $hToggleVideo
			If Not ($bLiveMode And $hDLProc <> 0) Then
				$bMP3Mode = False
				$bLiveMode = False
				$g_bLiveSel = False
				_FmtPaint($hToggleVideo, $hToggleMP3, $hToggleLive, 0)
				_ModePaint($hToggleSingle, $hTogglePlaylist)
				_ModeStatus($hStatus)
				_RefreshInputLink($hInput)
			EndIf
		Case $iMsg = $hToggleMP3
			If Not ($bLiveMode And $hDLProc <> 0) Then
				$bMP3Mode = True
				$bLiveMode = False
				$g_bLiveSel = False
				_FmtPaint($hToggleVideo, $hToggleMP3, $hToggleLive, 1)
				_ModePaint($hToggleSingle, $hTogglePlaylist)
				_ModeStatus($hStatus)
				_RefreshInputLink($hInput)
			EndIf
		Case $iMsg = $hToggleLive
			If $hDLProc = 0 Then
				$bLiveMode = True
				$g_bLiveSel = True
				_FmtPaint($hToggleVideo, $hToggleMP3, $hToggleLive, 2)
				_ModePaint($hToggleSingle, $hTogglePlaylist)
				_ModeStatus($hStatus)
				_RefreshInputLink($hInput)
			EndIf
			; Toggle: Einzeln
		Case $iMsg = $hToggleSingle
			If $g_bLiveSel Then ; leave Live: back to the last format (Video/Audio) with the clicked mode
				If $hDLProc = 0 Then
					$bLiveMode = False
					$g_bLiveSel = False
					$BP_bPlaylistMode = False
					_FmtPaint($hToggleVideo, $hToggleMP3, $hToggleLive, $bMP3Mode ? 1 : 0)
					_ModePaint($hToggleSingle, $hTogglePlaylist)
					_ModeStatus($hStatus)
					_RefreshInputLink($hInput)
				EndIf
			ElseIf $BP_bPlaylistMode Then
				$BP_bPlaylistMode = False
				GUICtrlSetBkColor($hToggleSingle, $CLR_ACCENT)
				GUICtrlSetColor($hToggleSingle, $CLR_TEXT)
				GUICtrlSetBkColor($hTogglePlaylist, 0x222222)
				GUICtrlSetColor($hTogglePlaylist, $CLR_MUTED)
				_ModeStatus($hStatus)
				_RefreshInputLink($hInput)
			EndIf
			; Toggle: Playlist
		Case $iMsg = $hTogglePlaylist
			If $g_bLiveSel Then ; leave Live: back to the last format (Video/Audio) with the clicked mode
				If $hDLProc = 0 Then
					$bLiveMode = False
					$g_bLiveSel = False
					$BP_bPlaylistMode = True
					_FmtPaint($hToggleVideo, $hToggleMP3, $hToggleLive, $bMP3Mode ? 1 : 0)
					_ModePaint($hToggleSingle, $hTogglePlaylist)
					_ModeStatus($hStatus)
					_RefreshInputLink($hInput)
				EndIf
			ElseIf Not $BP_bPlaylistMode Then
				$BP_bPlaylistMode = True
				GUICtrlSetBkColor($hTogglePlaylist, $CLR_ACCENT)
				GUICtrlSetColor($hTogglePlaylist, $CLR_TEXT)
				GUICtrlSetBkColor($hToggleSingle, 0x222222)
				GUICtrlSetColor($hToggleSingle, $CLR_MUTED)
				_ModeStatus($hStatus)
				_RefreshInputLink($hInput)
			EndIf
			; Download / Stop Toggle
		Case $iMsg = $hBtnDownload Or $iMsg = $hProgBG Or $iMsg = $hProgBar ; (the transparent text label lets clicks through to the bar labels)
			If $hDLProc <> 0 Then
				ProcessClose($hDLProc)
				$hDLProc = 0
				Local $oProcs = ProcessList()
				For $p = 1 To $oProcs[0][0]
					Select
						Case StringInStr($oProcs[$p][0], "yt-dlp")
							ProcessClose($oProcs[$p][1])
						Case StringInStr($oProcs[$p][0], "ffmpeg")
							ProcessClose($oProcs[$p][1])
					EndSelect
				Next
				GUICtrlSetPos($hProgBar, 24, $PROG_Y, 0, $PROG_H)
				GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
				$BP_bPlayerOpened = False
				BP_DropLive()
				GUICtrlSetData($hProgLabel, _L("Stopped."))
				GUICtrlSetData($hProgPct, "")
				_SetStatus($hStatus, "Download stopped.", 0xFFAA00)
				GUICtrlSetData($hBtnDownload, _L("Start"))
				_UpdateStartAppearance($hBtnDownload, _DetectURL(GUICtrlRead($hInput), $g_bDomainLinks) <> "")
			Else
				_RefreshInputLink($hInput)
				Local $sRaw = GUICtrlRead($hInput)
				$sRaw = StringStripWS($sRaw, 3)
				If $sRaw = "" Then
					_SetStatus($hStatus, "NO Link.", 0xFFAA00)
				Else
					Local $sNorm = _DetectURL($sRaw, $g_bDomainLinks)
					If $sNorm <> "" Then $sRaw = $sNorm
					Local $sClean = _CleanURL($sRaw)
					$g_sLastAutoURL = $sRaw
					If $bLiveMode Then
						_StartLive($sClean, $hProgBar, $hProgLabel, $hProgPct, $hBtnDownload, $PROG_Y, $PROG_H)
					Else
						_StartDownload($sClean, $hStatus, $hProgBar, $hProgLabel, $hProgPct)
					EndIf
				EndIf
			EndIf
			; Einfuegen & Start
		Case $iMsg = $hBtnPaste
			If $hDLProc <> 0 Then
				_SetStatus($hStatus, "Stop first!", 0xFFAA00)
			Else
				Local $sClip = ClipGet()
				If $sClip = "" Then
					_SetStatus($hStatus, "ClipBoard Empty.", 0xFFAA00)
				Else
					GUICtrlSetData($hInput, $sClip)
					Local $sClean = _CleanURL($sClip)
					_StartDownload($sClean, $hStatus, $hProgBar, $hProgLabel, $hProgPct)
				EndIf
			EndIf
			; Datei abspielen
		Case $iMsg = $hBtnPlay
			If $sLastFile <> "" And FileExists($sLastFile) And Not $g_bUseBP And Not $BP_bPlayerMode Then
				_PlayFile($sLastFile) ; internal player disabled -> registered system player
			ElseIf $sLastFile <> "" And FileExists($sLastFile) Then
				$g_sPlayReq = $sLastFile ; handled at the top of the loop
			ElseIf $sLastFile <> "" Then
				_SetStatus($hStatus, _L("File not found: ") & $sLastFile, 0xFF5252)
			Else
				_SetStatus($hStatus, "No download completed yet.", 0xFFAA00)
			EndIf
			; Download-Ordner oeffnen
		Case $iMsg = $hBtnFolder
			ShellExecute($DL_DIR)
	EndSelect
WEnd
BP_Quit()
GUIDelete($hGUI)
Exit
; Single/Multi-Knoepfe neu zeichnen (bei Live ausgegraut)
Func _ModePaint($hSingle, $hMulti)
	If $g_bLiveSel Then
		GUICtrlSetBkColor($hSingle, 0x222222)
		GUICtrlSetColor($hSingle, $CLR_MUTED)
		GUICtrlSetBkColor($hMulti, 0x222222)
		GUICtrlSetColor($hMulti, $CLR_MUTED)
	Else
		GUICtrlSetBkColor($hSingle, $BP_bPlaylistMode ? 0x222222 : $CLR_ACCENT)
		GUICtrlSetColor($hSingle, $BP_bPlaylistMode ? $CLR_MUTED : $CLR_TEXT)
		GUICtrlSetBkColor($hMulti, $BP_bPlaylistMode ? $CLR_ACCENT : 0x222222)
		GUICtrlSetColor($hMulti, $BP_bPlaylistMode ? $CLR_TEXT : $CLR_MUTED)
	EndIf
EndFunc   ;==>_ModePaint
Func _FmtPaint($hV, $hM, $hL, $iSel) ; 0 = Video, 1 = Audio, 2 = Live
	Local $aH[3] = [$hV, $hM, $hL]
	For $i = 0 To 2
		GUICtrlSetBkColor($aH[$i], $i = $iSel ? $CLR_ACCENT : 0x222222)
		GUICtrlSetColor($aH[$i], $i = $iSel ? $CLR_TEXT : $CLR_MUTED)
	Next
EndFunc   ;==>_FmtPaint
; URL-Erkennung: HTTP(S) oder Domain ohne Schema (z.B. example.de/path)
Func _DetectURL($sText, $bAllowDomain = True)
	$sText = StringStripWS($sText, 3)
	If $sText = "" Then Return ""
	; Nur eine URL pro Clipboard-Inhalt; Zeilenumbrüche/Leerzeichen abschneiden
	Local $aHTTP = StringRegExp($sText, "(?i)(https?://[^\s<>]+)", 1)
	If IsArray($aHTTP) And UBound($aHTTP) > 0 Then Return StringRegExpReplace($aHTTP[0], "[),.;]+$", "")
	If Not $bAllowDomain Then Return ""
	Local $aDomain = StringRegExp($sText, "(?i)^((?:www\.)?[a-z0-9][a-z0-9.-]*\.[a-z]{2,}(?::[0-9]{1,5})?(?:/[^\s<>]*)?)$", 1)
	If IsArray($aDomain) And UBound($aDomain) > 0 Then Return "https://" & StringRegExpReplace($aDomain[0], "[),.;]+$", "")
	Return ""
EndFunc   ;==>_DetectURL
Func _UpdateStartAppearance($hButton, $bHasLink)
	If $g_iStartState = ($bHasLink ? 1 : 0) Then Return ; nur bei Aenderung neu zeichnen (sonst flackert der Button)
	$g_iStartState = $bHasLink ? 1 : 0
	If $bHasLink Then
		_BtnBk($hButton, 0x00AA44)
		GUICtrlSetColor($hButton, 0xFFFFFF)
	Else
		_BtnBk($hButton, 0x333333)
		GUICtrlSetColor($hButton, 0x888888)
	EndIf
EndFunc   ;==>_UpdateStartAppearance
; Colour of the Start/Stop button: the main button is a text label on top of the bar, so its colour lives on the track label
Func _BtnBk($hBtn, $iColor)
	If $hBtn = $hBtnDownload Then
		GUICtrlSetBkColor($hProgBG, $iColor)
	Else
		GUICtrlSetBkColor($hBtn, $iColor)
	EndIf
EndFunc   ;==>_BtnBk
; ============================================================
;  Show/Hide Normal Controls
; ============================================================
Func _ShowNormalControls($iState, $hLabelURL, $hInput, $hLine2, $hLabelFormat, $hToggleVideo, $hToggleMP3, $hLabelPlaylist, $hToggleSingle, $hTogglePlaylist, $hBtnDownload, $hBtnPaste, $hLine3, $hProgLabel, $hProgPct, $hProgBG, $hProgBar, $hLine4, $hBtnPlay, $hBtnFolder, $hPlayLabel, $hStatus, $hToggleLive)
	GUICtrlSetState($hLabelURL, $iState)
	GUICtrlSetState($hInput, $iState)
	GUICtrlSetState($hLine2, $iState)
	GUICtrlSetState($hLabelFormat, $iState)
	GUICtrlSetState($hToggleVideo, $iState)
	GUICtrlSetState($hToggleMP3, $iState)
	GUICtrlSetState($hLabelPlaylist, $iState)
	GUICtrlSetState($hToggleSingle, $iState)
	GUICtrlSetState($hTogglePlaylist, $iState)
	GUICtrlSetState($hBtnDownload, $iState)
	; PasteStart bleibt dauerhaft deaktiviert/ausgeblendet; Clipboard-Watcher übernimmt die Funktion.
	GUICtrlSetState($hLine3, $iState)
	GUICtrlSetState($hProgLabel, $iState)
	GUICtrlSetState($hProgBG, $iState)
	GUICtrlSetState($hProgBar, $iState)
	GUICtrlSetState($hLine4, $iState)
	GUICtrlSetState($hBtnPlay, $iState)
	GUICtrlSetState($hBtnFolder, $iState)
	GUICtrlSetState($hPlayLabel, $iState)
	GUICtrlSetState($hStatus, $iState)
	GUICtrlSetState($hToggleLive, $iState)
EndFunc   ;==>_ShowNormalControls
; ============================================================
;  Show/Hide Live Controls
; ============================================================
Func _ShowLiveControls($iState, $hLiveBanner, $hLiveTitle, $hLiveLabelURL, $hLiveInput, $hLiveInfo, $hLiveBtnStart, $hLiveBtnPaste, $hLiveLine, $hLiveProgLabel, $hLiveProgSize, $hLiveProgBG, $hLiveProgBar)
	GUICtrlSetState($hLiveBanner, $iState)
	GUICtrlSetState($hLiveTitle, $iState)
	GUICtrlSetState($hLiveLabelURL, $iState)
	GUICtrlSetState($hLiveInput, $iState)
	GUICtrlSetState($hLiveInfo, $iState)
	GUICtrlSetState($hLiveBtnStart, $iState)
	GUICtrlSetState($hLiveBtnPaste, $iState)
	GUICtrlSetState($hLiveLine, $iState)
	GUICtrlSetState($hLiveProgLabel, $iState)
	GUICtrlSetState($hLiveProgSize, $iState)
	GUICtrlSetState($hLiveProgBG, $iState)
	GUICtrlSetState($hLiveProgBar, $iState)
EndFunc   ;==>_ShowLiveControls
; ============================================================
;  URL bereinigen
; ============================================================
Func _CleanURL($sURL)
	$sURL = StringStripWS($sURL, 3)
	If $BP_bPlaylistMode And Not $g_bLiveSel Then Return $sURL ; Multi: keep the full link (list= and so on)
	; YouTube: keep only the video id - works with v= anywhere in the query (watch?list=..&v=..), youtu.be, shorts/live/embed
	Local $aYT = StringRegExp($sURL, "(?i)^https?://(?:www\.|m\.|music\.)?youtube\.com/watch\?(?:[^#]*&)?v=([\w-]{6,})", 1)
	If IsArray($aYT) Then Return "https://www.youtube.com/watch?v=" & $aYT[0]
	Local $aYB = StringRegExp($sURL, "(?i)^https?://youtu\.be/([\w-]{6,})", 1)
	If IsArray($aYB) Then Return "https://www.youtube.com/watch?v=" & $aYB[0]
	Local $aYS = StringRegExp($sURL, "(?i)^https?://(?:www\.|m\.)?youtube\.com/(?:shorts|live|embed)/([\w-]{6,})", 1)
	If IsArray($aYS) Then Return "https://www.youtube.com/watch?v=" & $aYS[0]
	; every other site: cut at the first & (as before)
	Local $iAmp = StringInStr($sURL, "&")
	If $iAmp > 0 Then $sURL = StringLeft($sURL, $iAmp - 1)
	Return $sURL
EndFunc   ;==>_CleanURL
; Single/Live: show the cleaned link in the input field. Multi: give the full link back if the field still holds its cleaned version.
Func _RefreshInputLink($hInput)
	Local $sCur = StringStripWS(GUICtrlRead($hInput), 3)
	If $sCur = "" Then Return
	If $BP_bPlaylistMode And Not $g_bLiveSel Then
		If $g_sRawLink <> "" And $sCur = $g_sCleanLink Then GUICtrlSetData($hInput, $g_sRawLink)
	Else
		Local $sDet = _DetectURL($sCur, $g_bDomainLinks)
		If $sDet = "" Then Return
		Local $sCl = _CleanURL($sDet)
		If $sCl <> $sCur Then
			$g_sRawLink = $sDet
			$g_sCleanLink = $sCl
			GUICtrlSetData($hInput, $sCl)
		EndIf
	EndIf
EndFunc   ;==>_RefreshInputLink
Func _OverMainWin($aPos) ; is the (visible) window under the screen point our main window?
	Local $tPt = DllStructCreate($tagPOINT)
	DllStructSetData($tPt, "X", $aPos[0])
	DllStructSetData($tPt, "Y", $aPos[1])
	Local $h = _WinAPI_WindowFromPoint($tPt)
	If Not $h Then Return True ; cannot tell -> assume yes
	Return _WinAPI_GetAncestor($h, 2) = $hGUI
EndFunc   ;==>_OverMainWin
; Status bar: format + mode info (replaces the hint texts next to the toggles)
Func _ModeStatus($hStatus)
	If $g_bLiveSel Then
		_SetStatus($hStatus, _L("Live: watch a livestream"), $CLR_MUTED)
	Else
		_SetStatus($hStatus, _L($bMP3Mode ? "Audio (MP3): best audio quality" : "Video (MP4): best video quality") & "   |   " & _L($BP_bPlaylistMode ? "Multi: download all files of the link" : "Single: download one file"), $CLR_MUTED)
	EndIf
EndFunc   ;==>_ModeStatus
; ============================================================
;  Language (DE / EN): _L("English text") -> text in the chosen language.
;  English is the key, so a missing entry just stays English.
; ============================================================
Func _L($sEn)
	If $g_sLang <> "de" Or $sEn = "" Then Return $sEn
	Static $sTbl = ""
	If $sTbl = "" Then $sTbl = @LF & _LTable() & @LF
	Local $iP = StringInStr($sTbl, @LF & $sEn & "|", 1)
	If $iP = 0 Then Return $sEn
	Local $iS = $iP + StringLen($sEn) + 2
	Local $iE = StringInStr($sTbl, @LF, 1, 1, $iS)
	Return StringMid($sTbl, $iS, $iE - $iS)
EndFunc   ;==>_L
Func _LangBtnText()
	Return ($g_sLang = "de") ? "Sprache: Deutsch" : "Language: English"
EndFunc   ;==>_LangBtnText
Func _ConsoleBtnText()
	Return $bShowCMD ? _L("Show download console: ON") : _L("Show download console: OFF")
EndFunc   ;==>_ConsoleBtnText
; Re-texts everything that is static (called when the language is switched in the options)
Func _ApplyLang()
	GUICtrlSetTip($hTitleText, _L("Options"))
	GUICtrlSetData($hLabelURL, _L("Data URL:"))
	GUICtrlSetData($hLabelFormat, _L("Format:"))
	GUICtrlSetData($hLabelPlaylist, _L("Mode:"))
	GUICtrlSetData($hToggleSingle, _L("Single"))
	GUICtrlSetData($hTogglePlaylist, _L("Multi"))
	GUICtrlSetData($hToggleLive, _L("Live"))
	GUICtrlSetData($hBtnPlay, _L("> Play last File"))
	GUICtrlSetData($hBtnFolder, _L("[>] View Downloads"))
	If $sLastFile = "" Then GUICtrlSetData($hPlayLabel, _L("No download completed yet."))
	If $hDLProc = 0 Then GUICtrlSetData($hBtnDownload, _L("Start"))
	Local $sPL = GUICtrlRead($hProgLabel)
	If $sPL = "Ready." Or $sPL = "Bereit." Then GUICtrlSetData($hProgLabel, _L("Ready."))
	WinSetTitle($g_hOptGUI, "", _L("MultiDL Options"))
	GUICtrlSetData($hOptTitle, _L("Link-Detection"))
	GUICtrlSetData($g_hOptClip, _L("Check for Links in Clipboard."))
	GUICtrlSetData($g_hOptDomain, _L("Resolve Links without http(s)"))
	GUICtrlSetData($g_hOptAuto, _L("Automatic-Mode"))
	GUICtrlSetData($hOptTitleP, _L("Player"))
	GUICtrlSetData($g_hOptBP, _L("Use internal player (BrAiNPlay)"))
	GUICtrlSetData($hOptTitle2, _L("Tools"))
	GUICtrlSetData($g_hOptConsole, _ConsoleBtnText())
	GUICtrlSetData($g_hOptUpdate, _L("Update all tools"))
	GUICtrlSetData($hOptTitle3, _L("Program"))
	GUICtrlSetData($g_hOptMulti, _L("Allow multiple instances (Multi-Run)"))
	GUICtrlSetData($g_hOptLang, _LangBtnText())
	GUICtrlSetData($g_hOptClose, _L("CLOSE"))
	; BrAiNPlay
	GUICtrlSetTip($BP_bTV, _L("Show / hide the video   (V = video on/off, F = fullscreen / window)"))
	GUICtrlSetData($BP_bTV, $BP_fVidOn ? _L("VIDEO ON") : _L("VIDEO OFF"))
	GUICtrlSetData($BP_bShuf, _L("SHUF"))
	GUICtrlSetData($BP_bLoop, _L("LOOP"))
	GUICtrlSetData($BP_bAddFile, _L("+ FILES"))
	GUICtrlSetData($BP_bAddD, _L("+ FOLDER"))
	GUICtrlSetData($BP_bDel, _L("REMOVE"))
	GUICtrlSetData($BP_bClr, _L("CLEAR"))
	GUICtrlSetData($BP_bSave, _L("SAVE"))
	GUICtrlSetData($BP_bLoad, _L("LOAD"))
	If Not $BP_fPlay Then GUICtrlSetData($BP_lblNow, _L("stopped"))
	BP_Apply() ; refreshes the VOL / BAL texts
	_ModeStatus($hStatus)
EndFunc   ;==>_ApplyLang
; "English|Deutsch" per line (no "|" inside the texts)
Func _LTable()
	Local $t = ""
	$t &= "Options|Optionen" & @LF
	$t &= "Data URL:|Link (URL):" & @LF
	$t &= "Mode:|Modus:" & @LF
	$t &= "Single|Einzeln" & @LF
	$t &= "Multi|Mehrfach" & @LF
	$t &= "Stop|Stopp" & @LF
	$t &= "Ready.|Bereit." & @LF
	$t &= "> Play last File|> Letzte Datei abspielen" & @LF
	$t &= "[>] View Downloads|[>] Downloads öffnen" & @LF
	$t &= "No download completed yet.|Noch kein Download abgeschlossen." & @LF
	$t &= "Download running...|Download läuft..." & @LF
	$t &= "Stopped.|Gestoppt." & @LF
	$t &= "Download stopped.|Download gestoppt." & @LF
	$t &= "NO Link.|Kein Link." & @LF
	$t &= "Stop first!|Erst stoppen!" & @LF
	$t &= "ClipBoard Empty.|Zwischenablage ist leer." & @LF
	$t &= "Clipboard empty.|Zwischenablage ist leer." & @LF
	$t &= "File not found: |Datei nicht gefunden: " & @LF
	$t &= "Link detected in clipboard.|Link aus Zwischenablage erkannt." & @LF
	$t &= "Live: watch a livestream|Live: Livestream ansehen" & @LF
	$t &= "Audio (MP3): best audio quality|Audio (MP3): beste Audioqualität" & @LF
	$t &= "Video (MP4): best video quality|Video (MP4): beste Videoqualität" & @LF
	$t &= "Multi: download all files of the link|Mehrfach: alle Dateien des Links laden" & @LF
	$t &= "Single: download one file|Einzeln: eine Datei laden" & @LF
	$t &= "Bad Link.|Ungültiger Link." & @LF
	$t &= "Bad URL.|Ungültige URL." & @LF
	$t &= "No URL entered.|Keine URL eingegeben." & @LF
	$t &= "Waiting for file...|Warte auf Datei..." & @LF
	$t &= "Starting Download...|Download startet..." & @LF
	$t &= "MP3 Download started ...|MP3-Download gestartet ..." & @LF
	$t &= "Video Download started ...|Video-Download gestartet ..." & @LF
	$t &= "yt-dlp.exe not found!|yt-dlp.exe nicht gefunden!" & @LF
	$t &= "ffmpeg.exe not found!|ffmpeg.exe nicht gefunden!" & @LF
	$t &= "needed in: |benötigt in: " & @LF
	$t &= "YouTube bot-check detected, waiting for IPv4 retry...|YouTube-Bot-Check erkannt, warte auf IPv4-Wiederholung..." & @LF
	$t &= "Bot-check detected. Retrying once with IPv4...|Bot-Check erkannt. Neuer Versuch mit IPv4..." & @LF
	$t &= "Bot-check detected, retrying with IPv4...|Bot-Check erkannt, neuer Versuch mit IPv4..." & @LF
	$t &= "YouTube bot-check detected. Retrying with --force-ipv4...|YouTube-Bot-Check erkannt. Neuer Versuch mit --force-ipv4..." & @LF
	$t &= "RETRY|NOCHMAL" & @LF
	$t &= "ERROR|FEHLER" & @LF
	$t &= "Download failed.|Download fehlgeschlagen." & @LF
	$t &= "ERROR! Live stream failed.|FEHLER! Livestream fehlgeschlagen." & @LF
	$t &= "Download DONE!|Download FERTIG!" & @LF
	$t &= "DONE! Saved to: |FERTIG! Gespeichert in: " & @LF
	$t &= "Done.|Fertig." & @LF
	$t &= "Done!|Fertig!" & @LF
	$t &= "Loading: |Lade: " & @LF
	$t &= "Merging / Converting...|Zusammenführen / Konvertieren..." & @LF
	$t &= "ERROR! Download failed. Enable the console in the options (>) for details.|FEHLER! Download fehlgeschlagen. Details: Konsole in den Optionen (>) aktivieren." & @LF
	$t &= "YouTube blocked you (bot-check)! Restart your router for a new IP.|YouTube hat dich blockiert (Bot-Check)! Router neu starten für eine neue IP." & @LF
	$t &= "ERROR 416 - too much still open! Reboot PC/router, then retry.|FEHLER 416 - zu viel noch offen! PC/Router neu starten, dann nochmal versuchen." & @LF
	$t &= "BLOCKED by YouTube (bot-check)! Restart your router (new IP) and try again in a bit.|Von YouTube BLOCKIERT (Bot-Check)! Router neu starten (neue IP) und später nochmal versuchen." & @LF
	$t &= "ERROR 416! Leftover connections/processes are blocking this. Reboot your PC (or router) and try again.|FEHLER 416! Übrig gebliebene Verbindungen/Prozesse blockieren das. PC (oder Router) neu starten und nochmal versuchen." & @LF
	$t &= "ERROR! Download failed (try LIVE-Mode!)|FEHLER! Download fehlgeschlagen (probier den LIVE-Modus!)" & @LF
	$t &= "Live: starting the player - this can take up to a minute under Wine/Linux, please wait...|Live: Player startet - unter Wine/Linux kann das bis zu einer Minute dauern, bitte warten..." & @LF
	$t &= "Live: player started.|Live: Player gestartet." & @LF
	$t &= "Live: waiting for stream data - the player opens automatically, please wait...|Live: warte auf Stream-Daten - der Player öffnet sich automatisch, bitte warten..." & @LF
	$t &= "Live: player running.|Live: Player läuft." & @LF
	$t &= "Checking for updates...|Suche nach Updates..." & @LF
	$t &= "Starting update...|Update startet..." & @LF
	$t &= "Updating...|Aktualisiere..." & @LF
	$t &= "Updating yt-dlp.exe...|Aktualisiere yt-dlp.exe..." & @LF
	$t &= "yt-dlp.exe updated!|yt-dlp.exe aktualisiert!" & @LF
	$t &= "yt-dlp update failed!|yt-dlp-Update fehlgeschlagen!" & @LF
	$t &= "Downloading ffmpeg... (~170 MB)|Lade ffmpeg herunter... (~170 MB)" & @LF
	$t &= "Unpacking ffmpeg.exe...|Entpacke ffmpeg.exe..." & @LF
	$t &= "ffmpeg.exe updated!|ffmpeg.exe aktualisiert!" & @LF
	$t &= "ffmpeg update failed - unpack error! |ffmpeg-Update fehlgeschlagen - Entpackfehler! " & @LF
	$t &= "ffmpeg download failed!|ffmpeg-Download fehlgeschlagen!" & @LF
	$t &= "Updating deno.exe...|Aktualisiere deno.exe..." & @LF
	$t &= "Unpacking deno.exe...|Entpacke deno.exe..." & @LF
	$t &= "All tools updated!|Alle Tools aktualisiert!" & @LF
	$t &= "yt-dlp + ffmpeg updated, deno failed.|yt-dlp + ffmpeg aktualisiert, deno fehlgeschlagen." & @LF
	$t &= "Update complete!|Update abgeschlossen!" & @LF
	$t &= "Update complete, but deno.exe could not be updated.|Update abgeschlossen, aber deno.exe konnte nicht aktualisiert werden." & @LF
	$t &= "Stop the download first!|Stoppe zuerst den Download!" & @LF
	$t &= "Close the player first (BP button) - the update progress is shown in the download view.|Schließe zuerst den Player (BP-Button) - der Update-Fortschritt wird in der Download-Ansicht angezeigt." & @LF
	$t &= "Update to v|Update auf v" & @LF
	$t &= " now?| jetzt?" & @LF
	$t &= "MultiDL restarts afterwards.|MultiDL startet danach neu." & @LF
	$t &= "Update download failed.|Update-Download fehlgeschlagen." & @LF
	$t &= "(Release needs an asset named |(Das Release braucht eine Datei namens " & @LF
	$t &= "Could not replace |Konnte nicht ersetzen: " & @LF
	$t &= "MultiDL Options|MultiDL Optionen" & @LF
	$t &= "Link-Detection|Link-Erkennung" & @LF
	$t &= "Check for Links in Clipboard.|Zwischenablage auf Links prüfen." & @LF
	$t &= "Resolve Links without http(s)|Links ohne http(s) erkennen" & @LF
	$t &= "Automatic-Mode|Automatik-Modus" & @LF
	$t &= "Use internal player (BrAiNPlay)|Internen Player verwenden (BrAiNPlay)" & @LF
	$t &= "Show download console: ON|Download-Konsole anzeigen: AN" & @LF
	$t &= "Show download console: OFF|Download-Konsole anzeigen: AUS" & @LF
	$t &= "Update all tools|Alle Tools aktualisieren" & @LF
	$t &= "Program|Programm" & @LF
	$t &= "Allow multiple instances (Multi-Run)|Mehrere Instanzen erlauben (Multi-Run)" & @LF
	$t &= "VIDEO ON|VIDEO AN" & @LF
	$t &= "VIDEO OFF|VIDEO AUS" & @LF
	$t &= "Show / hide the video   (V = video on/off, F = fullscreen / window)|Video ein-/ausblenden   (V = Video an/aus, F = Vollbild / Fenster)" & @LF
	$t &= "stopped|gestoppt" & @LF
	$t &= "SHUF|ZUFALL" & @LF
	$t &= "LOOP|SCHLEIFE" & @LF
	$t &= "+ FILES|+ DATEIEN" & @LF
	$t &= "+ FOLDER|+ ORDNER" & @LF
	$t &= "REMOVE|ENTFERNEN" & @LF
	$t &= "CLEAR|LEEREN" & @LF
	$t &= "SAVE|SPEICHERN" & @LF
	$t &= "LOAD|LADEN" & @LF
	$t &= "VOL|LAUT" & @LF
	$t &= "BAL n/a|BAL n.v." & @LF
	$t &= "video needs Windows Media Player (Legacy) or a codec pack|Video braucht den Windows Media Player (Legacy) oder ein Codec-Pack" & @LF
	$t &= "can't play this file|Datei kann nicht abgespielt werden" & @LF
	$t &= "only one monitor|nur ein Monitor" & @LF
	$t &= "video on monitor |Video auf Monitor " & @LF
	$t &= "zoom is not available for WMP videos|Zoom ist für WMP-Videos nicht verfügbar" & @LF
	$t &= "zoom |Zoom " & @LF
	$t &= "audio track selection is not available in MCI mode|Audiospur-Auswahl ist im MCI-Modus nicht verfügbar" & @LF
	$t &= "audio: only one track|Audio: nur eine Spur" & @LF
	$t &= "audio |Audio " & @LF
	$t &= "Add files|Dateien hinzufügen" & @LF
	$t &= "Add folder|Ordner hinzufügen" & @LF
	$t &= "Save playlist|Playlist speichern" & @LF
	$t &= "Load playlist|Playlist laden" & @LF
	$t &= "CLOSE|SCHLIESSEN"
	Return $t
EndFunc   ;==>_LTable
; Gibt den --js-runtimes Parameter zurueck falls deno.exe vorhanden ist, sonst leer
Func _JsRuntimeArg()
	If FileExists($DENO_EXE) Then Return ' --js-runtimes deno:"' & $DENO_EXE & '"'
	Return ""
EndFunc   ;==>_JsRuntimeArg
; ============================================================
;  Erkennt YouTubes "Sign in to confirm you're not a bot"-Sperre.
;  Das ist kein normaler Download-Fehler sondern eine IP-basierte
;  Bot-Sperre - hilft nur Router neustarten (neue IP vom Provider)
;  oder eine Weile warten, kein Retry oder Cookie-Frickelei noetig.
; ============================================================
Func _IsBotBlockLine($s)
	Return (StringInStr($s, "not a bot", 0, 1) > 0) _
			Or (StringInStr($s, "Sign in to confirm", 0, 1) > 0) _
			Or (StringInStr($s, "confirm you're not a bot", 0, 1) > 0) _
			Or (StringInStr($s, "confirm you are not a bot", 0, 1) > 0)
EndFunc   ;==>_IsBotBlockLine
; Fuegt den IPv4-Fallback genau einmal zu einem bestehenden yt-dlp-Aufruf hinzu.
Func _ForceIPv4CMD($sCMD)
	If StringInStr($sCMD, " --force-ipv4", 0, 1) > 0 Then Return $sCMD
	Return StringReplace($sCMD, " --newline", " --force-ipv4 --newline", 1, 1)
EndFunc   ;==>_ForceIPv4CMD
; ============================================================
;  Erkennt HTTP 416 ("Requested Range Not Satisfiable"). Passiert
;  vor allem wenn noch alte yt-dlp/ffmpeg-Prozesse (z.B. nach einem
;  Absturz) im Hintergrund haengen und gleichzeitig auf dieselbe
;  YouTube-Session/Range zugreifen - YouTube blockt dann teilweise
;  mit 416. Hilft nur: die haengenden Prozesse weg (siehe
;  _KillStaleProcesses) und/oder eine neue IP (Router-Reboot).
; ============================================================
Func _Is416Line($s)
	Return StringInStr($s, "416", 0, 1) > 0 _
			And (StringInStr($s, "Requested range", 0, 1) > 0 _
			Or StringInStr($s, "Range Not Satisfiable", 0, 1) > 0 _
			Or StringInStr($s, "HTTP Error 416", 0, 1) > 0)
EndFunc   ;==>_Is416Line
Func _DLErrorLabel($sRaw)
	If _IsBotBlockLine($sRaw) Then Return _L("YouTube blocked you (bot-check)! Restart your router for a new IP.")
	If _Is416Line($sRaw) Then Return _L("ERROR 416 - too much still open! Reboot PC/router, then retry.")
	Return StringLeft(StringRegExpReplace($sRaw, "\s+", " "), 150)
EndFunc   ;==>_DLErrorLabel
Func _DLErrorStatus($sRaw)
	If _IsBotBlockLine($sRaw) Then Return _L("BLOCKED by YouTube (bot-check)! Restart your router (new IP) and try again in a bit.")
	If _Is416Line($sRaw) Then Return _L("ERROR 416! Leftover connections/processes are blocking this. Reboot your PC (or router) and try again.")
	Return _L("ERROR! Download failed (try LIVE-Mode!)")
EndFunc   ;==>_DLErrorStatus
; ============================================================
;  Datei mit dem passenden Player oeffnen.
;  Unter Wine/Linux gibt's meist keine Datei-Assoziation fuer mp4,
;  ShellExecute() laeuft dann ins Leere - deshalb dort ffplay
;  nutzen (liegt eh schon neben ffmpeg.exe). Unter echtem Windows
;  ganz normal der vom Nutzer registrierte Standardplayer.
; ============================================================
Func _PlayFile($sFile)
	If _IsWine() And FileExists($FFPLAY_EXE) Then
		Run('"' & $FFPLAY_EXE & '" -window_title "MultiDL" -loglevel error "' & $sFile & '"')
		_HideWineConsole()
	Else
		ShellExecute($sFile)
	EndIf
EndFunc   ;==>_PlayFile
; ============================================================
;  Wine haengt an jeden gestarteten Konsolen-Prozess (ffplay.exe
;  ist ein Konsolen-Subsystem-Build) automatisch ein sichtbares
;  "cmd"-Fenster (Wine-Konsole) mit an. Das laesst sich nicht
;  verhindern - und schliesst man dieses Fenster, haengt ffplay
;  am selben Konsolen-Handle und stirbt gleich mit. Deshalb hier
;  NICHT schliessen, sondern nur verstecken. Das Fenster taucht
;  quasi sofort nach dem Run() auf, kurzer WinWait reicht.
;  Die Video-Ausgabe von ffplay laeuft ueber ein eigenes SDL-
;  Fenster mit Titel "MultiDL" (siehe -window_title oben) und
;  ist von diesem Konsolen-Fenster komplett getrennt - die wird
;  hier also nicht mitversteckt.
; ============================================================
Func _HideWineConsole()
	Local $hConsole = WinWait("[REGEXPTITLE:(?i).*ffplay\.exe.*]", "", 3)
	If $hConsole <> 0 Then WinSetState($hConsole, "", @SW_HIDE)
EndFunc   ;==>_HideWineConsole
; ============================================================
;  Live-View: yt-dlp starten, Datei oeffnen
; ============================================================
Func _StartLive($sURL, $hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart, $iProgY = 290, $iProgH = 10)
	If $hDLProc <> 0 Then Return
	$sURL = StringStripWS($sURL, 3)
	If _IsSunoURL($sURL) Then $sURL = _SunoRewriteURL($sURL)     ; <-- NEU
	If Not StringRegExp($sURL, "(?i)^https?://") Then
		GUICtrlSetData($hLiveProgLabel, _L("Bad URL."))
		Return
	EndIf
	Local $iAmp = StringInStr($sURL, "&")
	If $iAmp > 0 Then $sURL = StringLeft($sURL, $iAmp - 1)
	GUICtrlSetPos($hLiveProgBar, 24, $iProgY, 0, $iProgH)
	GUICtrlSetBkColor($hLiveProgBar, 0x0088FF)
	GUICtrlSetData($hLiveProgLabel, _L("Waiting for file..."))
	GUICtrlSetData($hLiveProgSize, "")
	GUICtrlSetData($hLiveBtnStart, _L("Stop"))
	_BtnBk($hLiveBtnStart, 0x444444)
	; HIER WAR DER FEHLER: ffmpeg-location gefehlt + extractor-args hinzugefuegt gegen 403
	Local $sCMD = '"' & $YTDLP_EXE & '" --ffmpeg-location "' & $BIN_DIR & '" --no-playlist --no-part --extractor-args "youtube:player_client=android,web"' & _JsRuntimeArg() & ' -f "best[ext=mp4]/best" --newline -o "' & $DL_DIR & '\_watch_live.mp4" "' & $sURL & '"'
	$g_sLiveCMD = $sCMD
	$g_bIPv4Retried = False
	$g_bBotBlock = False
	BP_DropLive()
	FileDelete($DL_DIR & "\_watch_live.mp4")
	If $bShowCMD Then Run('cmd.exe /k "' & $sCMD & '"', $DL_DIR, @SW_SHOW)
	$bDLFailed = False
	$sDLError = ""
	$hDLProc = Run($sCMD, $DL_DIR, @SW_HIDE, 6)
	$g_iLiveStartTick = TimerInit()
EndFunc   ;==>_StartLive
; ============================================================
;  Live-Fortschritt lesen
; ============================================================
Func _ReadLiveProgress($hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart, $iProgY = 290, $iProgH = 10, $hStatus = 0)
	Static Local $iPulse = 0, $iPulseDir = 1
	Local $iFull = ($hLiveProgBar = $hProgBar) ? 0 : 512 ; main window: the Start/Stop button bar empties again at the end
	Static Local $iNote = 0, $iNoteFor = 0, $tNote = 0 ; status hint: 0 none, 1 waiting for stream data, 2 player is starting
	If $iNoteFor <> $g_iLiveStartTick Then ; new live start (or IPv4 retry) -> start the hints again
		$iNoteFor = $g_iLiveStartTick
		$iNote = 0
	EndIf
	; yt-dlp kann Fehler auf STDERR ausgeben. Bei Run(..., 6) lesen wir deshalb
	; beide Pipes. Wichtig: @error bei StdoutRead ist KEIN Erfolgs-Signal.
	Local $sStdout = StdoutRead($hDLProc)
	Local $sStderr = StderrRead($hDLProc)
	; Beide Ausgaben gemeinsam verarbeiten.
	Local $sAllOutput = $sStdout & @LF & $sStderr
	If $sAllOutput <> @LF Then
		Local $aLines = StringSplit($sAllOutput, @LF, 1)
		For $i = 1 To $aLines[0]
			Local $sTrimmed = StringStripWS($aLines[$i], 3)
			If StringLen($sTrimmed) < 4 Then ContinueLoop
			; YouTube Bot-Login erkannt: nicht sofort als Fehler anzeigen.
			; Der Prozess darf sauber beenden und wird danach genau einmal
			; mit --force-ipv4 neu gestartet.
			If _IsBotBlockLine($sTrimmed) Then
				$g_bBotBlock = True
				$bDLFailed = True
				$sDLError = $sTrimmed
				ContinueLoop
			EndIf
			; Groesse aus [download]-Zeile
			Local $aSize = StringRegExp($sTrimmed, "\[download\]\s+([\d\.]+\s*(?:KiB|MiB|GiB))", 1)
			If Not @error And UBound($aSize) >= 1 Then
				GUICtrlSetData($hLiveProgSize, $aSize[0])
				Local $sShort = StringRegExpReplace($sTrimmed, "^\[download\]\s+", "")
				If StringLen($sShort) > 65 Then $sShort = StringLeft($sShort, 65) & "..."
				GUICtrlSetData($hLiveProgLabel, $sShort)
				$iPulse += $iPulseDir * 24
				If $iPulse >= 480 Then $iPulseDir = -1
				If $iPulse <= 0 Then $iPulseDir = 1
				GUICtrlSetPos($hLiveProgBar, 24, $iProgY, $iPulse, $iProgH)
				ContinueLoop
			EndIf
			If StringInStr($sTrimmed, "ERROR", 0, 1) > 0 _
					Or StringInStr($sTrimmed, "403 Forbidden", 0, 1) > 0 _
					Or StringInStr($sTrimmed, "HTTP Error 403", 0, 1) > 0 _
					Or StringInStr($sTrimmed, "HTTP Error 416", 0, 1) > 0 Then
				$bDLFailed = True
				$sDLError = $sTrimmed
			EndIf
		Next
	EndIf
	; Player einmalig oeffnen sobald Datei da ist.
	If Not $BP_bPlayerOpened Then
		Local $sOutFile = $DL_DIR & "\_watch_live.mp4"
		If FileExists($sOutFile) And TimerDiff($g_iLiveStartTick) > 2000 Then
			If $g_bUseBP Then
				$g_sPlayReq = $sOutFile ; same logic as "Play last File": BrAiNPlay opens it
			Else
				_PlayFile($sOutFile)
			EndIf
			$BP_bPlayerOpened = True
			If $hStatus <> 0 Then
				If _IsWine() Then
					_SetStatus($hStatus, "Live: starting the player - this can take up to a minute under Wine/Linux, please wait...", 0xFFAA00)
					$iNote = 2
					$tNote = TimerInit()
				Else
					_SetStatus($hStatus, "Live: player started.", 0x4FC3F7)
				EndIf
			EndIf
		ElseIf $hStatus <> 0 And $iNote = 0 Then
			_SetStatus($hStatus, "Live: waiting for stream data - the player opens automatically, please wait...", 0x4FC3F7)
			$iNote = 1
		EndIf
	ElseIf $iNote = 2 And $hStatus <> 0 Then ; ffplay window (SDL) is up, or give up waiting for it
		If WinExists("[CLASS:SDL_app]") Or TimerDiff($tNote) > 120000 Then
			_SetStatus($hStatus, "Live: player running.", 0x00AA44)
			$iNote = 0
		EndIf
	EndIf
	; Prozess laeuft noch, also weiterwarten.
	If ProcessExists($hDLProc) Then Return
	; ------------------------------------------------------------
	; Bot-Check: genau EIN Retry mit --force-ipv4.
	; Erst wenn auch dieser Lauf wieder am Bot-Check scheitert,
	; wird der Fehler endgueltig angezeigt.
	; ------------------------------------------------------------
	If $g_bBotBlock And Not $g_bIPv4Retried Then
		$g_bIPv4Retried = True
		$g_bBotBlock = False
		$bDLFailed = False
		$sDLError = ""
		BP_DropLive()
		FileDelete($DL_DIR & "\_watch_live.mp4")
		$BP_bPlayerOpened = False
		$g_iLiveStartTick = TimerInit()
		$iPulse = 0
		$iPulseDir = 1
		GUICtrlSetPos($hLiveProgBar, 24, $iProgY, 0, $iProgH)
		GUICtrlSetBkColor($hLiveProgBar, 0x0088FF)
		GUICtrlSetData($hLiveProgLabel, _L("Bot-check detected, retrying with IPv4..."))
		GUICtrlSetData($hLiveProgSize, "")
		GUICtrlSetData($hLiveBtnStart, _L("Stop"))
		_BtnBk($hLiveBtnStart, 0x444444)
		Local $sRetryCMD = _ForceIPv4CMD($g_sLiveCMD)
		If $bShowCMD Then Run('cmd.exe /k "' & $sRetryCMD & '"', $DL_DIR, @SW_SHOW)
		$hDLProc = Run($sRetryCMD, $DL_DIR, @SW_HIDE, 6)
		Return
	EndIf
	; Zweiter Bot-Check oder anderer Live-Fehler: NICHT "Done." anzeigen.
	If $bDLFailed Then
		; Bei 416 nochmal Leichencheck - vielleicht haengt gerade neu was rum.
		If _Is416Line($sDLError) Then _KillStaleProcesses()
		GUICtrlSetPos($hLiveProgBar, 24, $iProgY, $iFull, $iProgH)
		GUICtrlSetBkColor($hLiveProgBar, 0xFF5252)
		GUICtrlSetData($hLiveProgSize, _L("ERROR"))
		If $sDLError <> "" Then
			GUICtrlSetData($hLiveProgLabel, _DLErrorLabel($sDLError))
		Else
			GUICtrlSetData($hLiveProgLabel, _L("ERROR! Live stream failed."))
		EndIf
		GUICtrlSetData($hLiveBtnStart, _L("Start"))
		_BtnBk($hLiveBtnStart, 0x880000)
		$hDLProc = 0
		$bDLFailed = False
		$sDLError = ""
		$g_bBotBlock = False
		Return
	EndIf
	; Prozess beendet sich ohne Fehler, z.B. weil der Live-Stream wirklich endet.
	GUICtrlSetPos($hLiveProgBar, 24, $iProgY, $iFull, $iProgH)
	GUICtrlSetBkColor($hLiveProgBar, 0x00AA44)
	GUICtrlSetData($hLiveProgLabel, _L("Done."))
	GUICtrlSetData($hLiveProgSize, "")
	GUICtrlSetData($hLiveBtnStart, _L("Start"))
	_BtnBk($hLiveBtnStart, 0x880000)
	$hDLProc = 0
	$BP_bPlayerOpened = False
EndFunc   ;==>_ReadLiveProgress
; ============================================================
;  yt-dlp starten (Video oder MP3)
; ============================================================
Func _StartDownload($sURL, $hStatusLabel, $hProgBar, $hProgLabel, $hProgPct)
	Local $sOutTemplate = "%(title)s.%(ext)s"
	If _IsSunoURL($sURL) Then
		Local $sSunoTitle = _SunoClipTitle(_SunoClipId($sURL))     ; <-- NEU: echten Titel per API holen, BEVOR die URL auf die cdn umgeschrieben wird
		If $sSunoTitle <> "" Then $sOutTemplate = $sSunoTitle & ".%(ext)s"
		$sURL = _SunoRewriteURL($sURL)
	EndIf
	If Not FileExists($YTDLP_EXE) Then
		MsgBox(16, $APP_TITLE, _L("yt-dlp.exe not found!") & @CRLF & _L("needed in: ") & $YTDLP_EXE)
		_SetStatus($hStatusLabel, "yt-dlp.exe not found!", 0xFF5252)
		Return
	EndIf
	If Not StringRegExp($sURL, "(?i)^https?://") Then
		_SetStatus($hStatusLabel, "Bad Link.", 0xFFAA00)
		Return
	EndIf
	GUICtrlSetPos($hProgBar, 24, $PROG_Y, 0, $PROG_H)
	GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
	GUICtrlSetData($hProgLabel, _L("Starting Download..."))
	GUICtrlSetData($hBtnDownload, _L("Stop"))
	_BtnBk($hBtnDownload, 0x3A0A0A) ; dark track, the red fill shows the progress
	GUICtrlSetData($hProgPct, "")
	$sLastFile = ""
	If Not $BP_bPlaylistMode Then
		GUICtrlSetBkColor($hBtnPlay, 0x1A3A1A)
		GUICtrlSetColor($hBtnPlay, $CLR_TEXT)
		GUICtrlSetData($hPlayLabel, _L("Download running..."))
		GUICtrlSetColor($hPlayLabel, $CLR_MUTED)
	EndIf
	Local $sCMD
	Local $sPlFlag = " --no-playlist"
	If $BP_bPlaylistMode Then $sPlFlag = " --yes-playlist"
	If $bMP3Mode Then
		If Not FileExists($FFMPEG_EXE) Then
			MsgBox(16, $APP_TITLE, _L("ffmpeg.exe not found!") & @CRLF & _L("needed in: ") & $FFMPEG_EXE)
			_SetStatus($hStatusLabel, "ffmpeg.exe not found!", 0xFF5252)
			Return
		EndIf
		_SetStatus($hStatusLabel, "MP3 Download started ...", 0x4FC3F7)
		$sCMD = '"' & $YTDLP_EXE & '" --ffmpeg-location "' & $BIN_DIR & '" --no-part --extractor-args "youtube:player_client=android,web"' & _JsRuntimeArg() & $sPlFlag & ' -x --audio-format mp3 --audio-quality 0 --newline -o "' & $DL_DIR & '\' & $sOutTemplate & '" "' & $sURL & '"'
	Else
		_SetStatus($hStatusLabel, "Video Download started ...", 0x4FC3F7)
		$sCMD = '"' & $YTDLP_EXE & '" --ffmpeg-location "' & $BIN_DIR & '" --no-part --extractor-args "youtube:player_client=android,web"' & _JsRuntimeArg() & $sPlFlag & ' -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4 --newline -o "' & $DL_DIR & '\' & $sOutTemplate & '" "' & $sURL & '"'
	EndIf
	If $bShowCMD Then Run('cmd.exe /k "' & $sCMD & '"', $DL_DIR, @SW_SHOW)
	$bDLFailed = False
	$sDLError = ""
	$g_bIPv4Retried = False
	$g_bBotBlock = False
	$g_sDownloadCMD = $sCMD
	$hDLProc = Run($sCMD, $DL_DIR, @SW_HIDE, 6) ; STDOUT + STDERR
EndFunc   ;==>_StartDownload
; ============================================================
;  Fortschritt aus yt-dlp Output lesen
; ============================================================
Func _ReadProgress($hProgBar, $hProgLabel, $hProgPct, $hStatus)
	; yt-dlp writes errors to STDERR. Therefore read BOTH pipes.
	Local $sStdout = StdoutRead($hDLProc)
	Local $sStderr = StderrRead($hDLProc)
	; Parse normal output.
	If $sStdout <> "" Then
		Local $aLines = StringSplit($sStdout, @LF, 1)
		For $i = 1 To $aLines[0]
			Local $sTrimmed = StringStripWS($aLines[$i], 3)
			If StringLen($sTrimmed) > 3 Then
				If _IsBotBlockLine($sTrimmed) Then
					$g_bBotBlock = True
					$bDLFailed = True
					$sDLError = $sTrimmed
				ElseIf StringInStr($sTrimmed, "ERROR", 0, 1) > 0 _
						Or StringInStr($sTrimmed, "403 Forbidden", 0, 1) > 0 _
						Or StringInStr($sTrimmed, "HTTP Error 403", 0, 1) > 0 _
						Or StringInStr($sTrimmed, "HTTP Error 416", 0, 1) > 0 Then
					$bDLFailed = True
					$sDLError = $sTrimmed
				Else
					_ParseProgressLine($sTrimmed, $hProgBar, $hProgLabel, $hProgPct, $hStatus)
				EndIf
			EndIf
		Next
	EndIf
	; Parse STDERR too. This is where yt-dlp normally prints errors.
	If $sStderr <> "" Then
		Local $aErrLines = StringSplit($sStderr, @LF, 1)
		For $i = 1 To $aErrLines[0]
			Local $sErrTrimmed = StringStripWS($aErrLines[$i], 3)
			If StringLen($sErrTrimmed) > 3 Then
				If _IsBotBlockLine($sErrTrimmed) Then
					$g_bBotBlock = True
					$bDLFailed = True
					$sDLError = $sErrTrimmed
				ElseIf StringInStr($sErrTrimmed, "ERROR", 0, 1) > 0 _
						Or StringInStr($sErrTrimmed, "403 Forbidden", 0, 1) > 0 _
						Or StringInStr($sErrTrimmed, "HTTP Error 403", 0, 1) > 0 _
						Or StringInStr($sErrTrimmed, "HTTP Error 416", 0, 1) > 0 Then
					$bDLFailed = True
					$sDLError = $sErrTrimmed
				EndIf
			EndIf
		Next
	EndIf
	; Prozess laeuft noch, also weiterwarten.
	If ProcessExists($hDLProc) Then
		If $g_bBotBlock Then
			GUICtrlSetData($hProgPct, _L("RETRY"))
			GUICtrlSetData($hProgLabel, _L("YouTube bot-check detected, waiting for IPv4 retry..."))
			_SetStatus($hStatus, "Bot-check detected. Retrying once with IPv4...", 0xFFAA00)
		EndIf
		Return
	EndIf
	; ------------------------------------------------------------
	; Bot-Check: genau EIN Retry mit --force-ipv4.
	; Erst wenn auch dieser Lauf wieder am Bot-Check scheitert,
	; wird der Fehler endgueltig angezeigt.
	; ------------------------------------------------------------
	If $g_bBotBlock And Not $g_bIPv4Retried Then
		$g_bIPv4Retried = True
		$g_bBotBlock = False
		$bDLFailed = False
		$sDLError = ""
		GUICtrlSetPos($hProgBar, 24, $PROG_Y, 0, $PROG_H)
		GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
		GUICtrlSetData($hProgPct, _L("RETRY"))
		GUICtrlSetData($hProgLabel, _L("Bot-check detected, retrying with IPv4..."))
		_SetStatus($hStatus, "YouTube bot-check detected. Retrying with --force-ipv4...", 0xFFAA00)
		Local $sRetryCMD = _ForceIPv4CMD($g_sDownloadCMD)
		If $bShowCMD Then Run('cmd.exe /k "' & $sRetryCMD & '"', $DL_DIR, @SW_SHOW)
		$hDLProc = Run($sRetryCMD, $DL_DIR, @SW_HIDE, 6)
		Return
	EndIf
	; Endgueltiger Fehler, inklusive zweitem Bot-Check.
	If $bDLFailed Then
		; Bei 416 nochmal Leichencheck - vielleicht haengt gerade neu was rum.
		If _Is416Line($sDLError) Then _KillStaleProcesses()
		GUICtrlSetPos($hProgBar, 24, $PROG_Y, 0, $PROG_H) ; button back to "Start" - the error stays in the label
		GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
		GUICtrlSetData($hProgPct, _L("ERROR"))
		If $sDLError <> "" Then
			GUICtrlSetData($hProgLabel, _DLErrorLabel($sDLError))
		Else
			GUICtrlSetData($hProgLabel, _L("Download failed."))
		EndIf
		_SetStatus($hStatus, _DLErrorStatus($sDLError), 0xFF5252)
		$hDLProc = 0
		$bDLFailed = False
		$sDLError = ""
		$g_bBotBlock = False
		GUICtrlSetData($hBtnDownload, _L("Start"))
		_BtnBk($hBtnDownload, 0x00AA44)
		Return
	EndIf
	; Process exited without an ERROR line: now it is safe to report DONE.
	GUICtrlSetPos($hProgBar, 24, $PROG_Y, 0, $PROG_H) ; button back to "Start" - DONE stays in the label
	GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
	GUICtrlSetData($hProgPct, "100%")
	GUICtrlSetData($hProgLabel, _L("Download DONE!"))
	_SetStatus($hStatus, _L("DONE! Saved to: ") & $DL_DIR, 0x00AA44)
	If $sLastFile = "" Or Not FileExists($sLastFile) Then
		Local $sSearch = FileFindFirstFile($DL_DIR & "\*.*")
		Local $sNewest = ""
		Local $tNewest = 0
		If $sSearch <> -1 Then
			Local $sFound = FileFindNextFile($sSearch)
			While Not @error
				Local $sFullPath = $DL_DIR & "\" & $sFound
				Local $sExt = StringLower(StringRight($sFound, 4))
				If $sExt = ".mp4" Or $sExt = ".mp3" Or $sExt = ".mkv" Or $sExt = ".webm" Then
					Local $tFile = FileGetTime($sFullPath, 0, 1)
					If $tFile > $tNewest Then
						$tNewest = $tFile
						$sNewest = $sFullPath
					EndIf
				EndIf
				$sFound = FileFindNextFile($sSearch)
			WEnd
			FileClose($sSearch)
		EndIf
		If $sNewest <> "" Then $sLastFile = $sNewest
	EndIf
	GUICtrlSetBkColor($hBtnPlay, 0x00AA44)
	GUICtrlSetColor($hBtnPlay, $CLR_TEXT)
	If $sLastFile <> "" Then
		Local $sDispName = $sLastFile
		Local $iSlash = StringInStr($sDispName, "\", 0, -1)
		If $iSlash > 0 Then $sDispName = StringMid($sDispName, $iSlash + 1)
		If StringLen($sDispName) > 60 Then $sDispName = StringLeft($sDispName, 60) & "..."
		GUICtrlSetData($hPlayLabel, "> " & $sDispName)
		GUICtrlSetColor($hPlayLabel, 0x00AA44)
	EndIf
	$hDLProc = 0
	GUICtrlSetData($hBtnDownload, _L("Start"))
	_BtnBk($hBtnDownload, 0x00AA44)
	BP_LoadDL() ; new files go into the BrAiNPlay playlist right away (player visible or not)
EndFunc   ;==>_ReadProgress
; ============================================================
;  Eine yt-dlp Output-Zeile auswerten
; ============================================================
Func _ParseProgressLine($sLine, $hProgBar, $hProgLabel, $hProgPct, $hStatus)
	Local $aMatch = StringRegExp($sLine, "\[download\]\s+([\d\.]+)%", 1)
	If Not @error And UBound($aMatch) >= 1 Then
		Local $fPct = Number($aMatch[0])
		If $fPct < 0 Then $fPct = 0
		If $fPct > 100 Then $fPct = 100
		Local $iWidth = Int(512 * $fPct / 100)
		Local $aFP = ControlGetPos($hGUI, "", $hProgBar)
		If Not IsArray($aFP) Or $aFP[2] <> $iWidth Then GUICtrlSetPos($hProgBar, 24, $PROG_Y, $iWidth, $PROG_H) ; only when it changed (avoids flicker)
		GUICtrlSetData($hProgPct, StringFormat("%.0f%%", $fPct))
		Local $sBtnTxt = _L("Stop") & "  " & StringFormat("%.0f%%", $fPct)
		If GUICtrlRead($hBtnDownload) <> $sBtnTxt Then GUICtrlSetData($hBtnDownload, $sBtnTxt)
		Local $sShort = StringRegExpReplace($sLine, "^\[download\]\s+", "")
		If StringLen($sShort) > 65 Then $sShort = StringLeft($sShort, 65) & "..."
		GUICtrlSetData($hProgLabel, $sShort)
		Return
	EndIf
	Local $aDest = StringRegExp($sLine, "\[download\] Destination: (.+)", 1)
	If Not @error And UBound($aDest) >= 1 Then
		$sLastFile = StringStripWS($aDest[0], 3)
		Local $sFile = $sLastFile
		Local $iSlash = StringInStr($sFile, "\", 0, -1)
		If $iSlash > 0 Then $sFile = StringMid($sFile, $iSlash + 1)
		If StringLen($sFile) > 65 Then $sFile = StringLeft($sFile, 65) & "..."
		GUICtrlSetData($hProgLabel, _L("Loading: ") & $sFile)
		Return
	EndIf
	Local $aMerge = StringRegExp($sLine, '\[Merger\].*?"(.+?)"', 1)
	If Not @error And UBound($aMerge) >= 1 Then
		Local $sMergedFile = StringStripWS($aMerge[0], 3)
		If Not StringRegExp($sMergedFile, "^[A-Za-z]:\\") Then
			$sMergedFile = $DL_DIR & "\" & $sMergedFile
		EndIf
		$sLastFile = $sMergedFile
		GUICtrlSetData($hProgLabel, _L("Merging / Converting..."))
		GUICtrlSetPos($hProgBar, 24, $PROG_Y, 490, $PROG_H)
		GUICtrlSetData($hProgPct, "~99%")
		Return
	EndIf
	If StringInStr($sLine, "[Merger]") Or StringInStr($sLine, "Merging") Or StringInStr($sLine, "ffmpeg") Then
		GUICtrlSetData($hProgLabel, _L("Merging / Converting..."))
		GUICtrlSetPos($hProgBar, 24, $PROG_Y, 490, $PROG_H)
		GUICtrlSetData($hProgPct, "~99%")
		Return
	EndIf
	If StringInStr($sLine, "ERROR") Then
		$bDLFailed = True
		$sDLError = $sLine
		GUICtrlSetBkColor($hProgBar, 0xFF5252)
		GUICtrlSetData($hProgLabel, _DLErrorLabel($sLine))
		If _IsBotBlockLine($sLine) Then
			_SetStatus($hStatus, _DLErrorStatus($sLine), 0xFF5252)
		Else
			_SetStatus($hStatus, "ERROR! Download failed. Enable the console in the options (>) for details.", 0xFF5252)
		EndIf
		; WICHTIG: $hDLProc bleibt gueltig, bis _ReadProgress den
		; Prozess wirklich beendet/den Stream nicht mehr lesen kann.
		; Sonst wird der naechste @error faelschlich als DONE behandelt.
		Return
	EndIf
EndFunc   ;==>_ParseProgressLine
; ============================================================
;  Wenn MultiDL vorher abgestuerzt ist (z.B. waehrend des Codens
;  im IDE beendet), koennen yt-dlp.exe/ffmpeg.exe von diesem Lauf
;  noch als Prozessleichen weiterlaufen - der naechste Start haut
;  dann u.a. mit HTTP 416 (Range Not Satisfiable) hin, weil yt-dlp
;  versucht eine halbfertige/blockierte Datei weiterzuladen deren
;  Zustand nicht mehr passt. Deshalb VOR allem anderen: alte
;  yt-dlp.exe/ffmpeg.exe Prozesse killen, damit nichts haengen
;  bleibt. ffplay.exe wird bewusst NICHT angefasst - falls da noch
;  ein Video vom letzten Lauf laeuft, soll das weiterlaufen duerfen.
; ============================================================
Func _KillStaleProcesses()
	Local $oProcs = ProcessList()
	For $p = 1 To $oProcs[0][0]
		If StringInStr($oProcs[$p][0], "yt-dlp") Or StringInStr($oProcs[$p][0], "ffmpeg") Then
			ProcessClose($oProcs[$p][1])
		EndIf
	Next
EndFunc   ;==>_KillStaleProcesses
; ============================================================
;  Startup Check: yt-dlp.exe und ffmpeg.exe pruefen & laden
; ============================================================
Func _StartupCheck()
	If Not FileExists($BIN_DIR) Then DirCreate($BIN_DIR)
	If Not FileExists($DL_DIR) Then DirCreate($DL_DIR)
	Local $bNeedYtdlp = Not FileExists($YTDLP_EXE)
	Local $bNeedFfmpeg = Not FileExists($FFMPEG_EXE)
	Local $bNeedDeno = Not FileExists($DENO_EXE)
	If Not $bNeedYtdlp And Not $bNeedFfmpeg And Not $bNeedDeno Then Return
	Local $hProg = GUICreate("preInstallation...", 420, 110, -1, -1, $WS_POPUP + $WS_BORDER)
	GUISetBkColor(0x0F0F0F, $hProg)
	Local $hProgTitle = GUICtrlCreateLabel("preInstallation...", 16, 12, 388, 20)
	GUICtrlSetFont($hProgTitle, 10, 700, 0, "Segoe UI")
	GUICtrlSetColor($hProgTitle, 0xF0F0F0)
	GUICtrlSetBkColor($hProgTitle, 0x0F0F0F)
	Local $hProgInfo = GUICtrlCreateLabel("Please Wait...", 16, 40, 388, 18)
	GUICtrlSetFont($hProgInfo, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor($hProgInfo, 0x888888)
	GUICtrlSetBkColor($hProgInfo, 0x0F0F0F)
	Local $hProgBG = GUICtrlCreateLabel("", 16, 68, 388, 8)
	GUICtrlSetBkColor($hProgBG, 0x222222)
	Local $hProgBar = GUICtrlCreateLabel("", 16, 68, 0, 8)
	GUICtrlSetBkColor($hProgBar, 0xFF0000)
	GUISetState(@SW_SHOW, $hProg)
	If $bNeedYtdlp Then
		GUICtrlSetData($hProgInfo, "Loading yt-dlp.exe from GitHub...")
		_ProgBar($hProgBar, 10)
		Local $sURL1 = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
		If Not _Download($sURL1, $YTDLP_EXE, $hProgBar, 10, 45) Then
			GUIDelete($hProg)
			MsgBox(16, $APP_TITLE, "Error: yt-dlp.exe could not be loaded." & @CRLF & "Please download manually: https://github.com/yt-dlp/yt-dlp/releases")
			Return
		EndIf
		_ProgBar($hProgBar, 45)
	EndIf
	If $bNeedFfmpeg Then
		GUICtrlSetData($hProgInfo, "Download ffmpeg from GitHub... (approx. 90 MB, takes a moment)")
		_ProgBar($hProgBar, 50)
		If Not FileExists($BIN_DIR) Then DirCreate($BIN_DIR)
		Local $sZip = $BIN_DIR & "\ffmpeg_tmp.zip"
		Local $sURL2 = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
		If Not _Download($sURL2, $sZip, $hProgBar, 50, 85) Then
			GUIDelete($hProg)
			MsgBox(16, $APP_TITLE, "Error: ffmpeg could not be loaded." & @CRLF & "Please download manually: https://github.com/BtbN/FFmpeg-Builds/releases")
			Return
		EndIf
		_ProgBar($hProgBar, 85)
		If _IsWine() Then
			GUICtrlSetData($hProgInfo, "Checking latest 7-Zip version...")
			Local $s7zrURL = _Get7zrURL()
			Local $aTag7z = StringRegExp($s7zrURL, "/download/([^/]+)/", 1)
			Local $sTag7z = (Not @error And UBound($aTag7z) >= 1) ? $aTag7z[0] : "26.00"
			Local $sVer7z = StringReplace($sTag7z, ".", "")
			Local $s7zaURL = "https://github.com/ip7z/7zip/releases/download/" & $sTag7z & "/7z" & $sVer7z & "-extra.7z"
			If Not FileExists($BIN_DIR & "\7zr.exe") Or FileGetSize($BIN_DIR & "\7zr.exe") < 100000 Then
				GUICtrlSetData($hProgInfo, "Downloading 7zr.exe (v" & $sTag7z & ")...")
				If Not _Download($s7zrURL, $BIN_DIR & "\7zr.exe", $hProgBar, 85, 88) Then
					GUIDelete($hProg)
					MsgBox(16, $APP_TITLE, _L("Error: 7zr.exe could not be downloaded."))
					Return
				EndIf
			EndIf
			If Not FileExists($BIN_DIR & "\7za.exe") Or FileGetSize($BIN_DIR & "\7za.exe") < 400000 Then
				FileDelete($BIN_DIR & "\7za.exe")
				GUICtrlSetData($hProgInfo, "Downloading 7za.exe...")
				If Not _Download($s7zaURL, $BIN_DIR & "\7z_extra.7z", $hProgBar, 88, 91) Then
					GUIDelete($hProg)
					MsgBox(16, $APP_TITLE, _L("Error: 7z_extra.7z could not be downloaded."))
					Return
				EndIf
				; War der Download ein 404/Fehlerseiten-Fallback (falscher Versions-Tag),
				; ist die Datei winzig statt ~1-2 MB - dann lieber sauber abbrechen
				; statt aus Muell ein "7za.exe" zu extrahieren
				If FileGetSize($BIN_DIR & "\7z_extra.7z") < 200000 Then
					FileDelete($BIN_DIR & "\7z_extra.7z")
					GUIDelete($hProg)
					MsgBox(16, $APP_TITLE, "Error: 7z-extra.7z Download war fehlerhaft (falscher Versions-Tag " & $sTag7z & "?)." & @CRLF & "Bitte 7za.exe manuell in " & $BIN_DIR & " ablegen.")
					Return
				EndIf
				GUICtrlSetData($hProgInfo, "Extracting 7za.exe...")
				RunWait('"' & $BIN_DIR & '\7zr.exe" e "' & $BIN_DIR & '\7z_extra.7z" 7za.exe -y', $BIN_DIR, @SW_HIDE)
				FileDelete($BIN_DIR & "\7z_extra.7z")
				If Not FileExists($BIN_DIR & "\7za.exe") Then
					GUIDelete($hProg)
					MsgBox(16, $APP_TITLE, "Error: 7za.exe could not be extracted." & @CRLF & "Please place 7za.exe manually in: " & $BIN_DIR)
					Return
				EndIf
			EndIf
		EndIf
		GUICtrlSetData($hProgInfo, "Unpacking ffmpeg.exe...")
		_UnzipFFmpeg($sZip, $BIN_DIR)
		FileDelete($sZip)
		_ProgBar($hProgBar, 100)
		If Not FileExists($FFMPEG_EXE) Then
			GUIDelete($hProg)
			MsgBox(16, $APP_TITLE, "Error: ffmpeg.exe could not be unpacked." & @CRLF & $g_sUnzipDebug)
			Return
		EndIf
	EndIf
	If $bNeedDeno Then
		; JS-Runtime fuer yt-dlp - YouTube verlangt inzwischen JS-Ausfuehrung
		; zum Entschluesseln der Video-Signatur, ohne das gibt's 403 Forbidden
		GUICtrlSetData($hProgInfo, "Downloading deno.exe (JS runtime for YouTube)...")
		_ProgBar($hProgBar, 92)
		Local $sDenoZip = $BIN_DIR & "\deno_tmp.zip"
		Local $sDenoURL = "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip"
		If _Download($sDenoURL, $sDenoZip, $hProgBar, 92, 98) Then
			GUICtrlSetData($hProgInfo, "Unpacking deno.exe...")
			If _IsWine() Then
				If FileExists($BIN_DIR & "\7za.exe") Then
					RunWait('"' & $BIN_DIR & '\7za.exe" x "' & $sDenoZip & '" -o"' & $BIN_DIR & '" -y', $BIN_DIR, @SW_HIDE)
				EndIf
			Else
				If Not _UnZipPS($sDenoZip, $BIN_DIR) Then _UnZip($sDenoZip, $BIN_DIR)
			EndIf
			FileDelete($sDenoZip)
			If Not FileExists($DENO_EXE) Then
				; deno.exe landete evtl. in einem Unterordner - nachsuchen
				Local $sFound = _FindFileRecursive($BIN_DIR, "deno.exe")
				If $sFound <> "" And $sFound <> $DENO_EXE Then FileMove($sFound, $DENO_EXE)
			EndIf
		EndIf
		; nicht fatal falls deno fehlschlaegt - yt-dlp laeuft dann halt ohne
		; JS-Runtime weiter (mit dem bekannten 403-Risiko)
		_ProgBar($hProgBar, 98)
	EndIf
	GUICtrlSetData($hProgInfo, "Done! Everything is ready.")
	_ProgBar($hProgBar, 100)
	Sleep(900)
	GUIDelete($hProg)
EndFunc   ;==>_StartupCheck
; ============================================================
;  Datei nativ per InetGet herunterladen (Wine-kompatibel)
; ============================================================
Func _Download($sURL, $sDest, $hProgBar = 0, $iProgStart = 0, $iProgEnd = 100, $iBarX = 16, $iBarY = 68, $iBarW = 388, $iBarH = 8)
	Local $hInet = InetGet($sURL, $sDest, $INET_FORCERELOAD, 1)
	Do
		If $hProgBar <> 0 Then
			Local $iReceived = InetGetInfo($hInet, 0)
			Local $iTotal = InetGetInfo($hInet, 1)
			If $iTotal > 0 Then
				Local $fPct = $iReceived / $iTotal
				Local $iRange = $iProgEnd - $iProgStart
				Local $iWidth = Int($iBarW * ($iProgStart / 100 + $fPct * $iRange / 100))
				GUICtrlSetPos($hProgBar, $iBarX, $iBarY, $iWidth, $iBarH)
			EndIf
		EndIf
		GUIGetMsg()
		Sleep(100)
	Until InetGetInfo($hInet, 2)
	InetClose($hInet)
	Local $iFlushWait = 0
	Do
		Sleep(100)
		$iFlushWait += 1
	Until (FileExists($sDest) And FileGetSize($sDest) > 0) Or $iFlushWait > 50
	If FileGetSize($sDest) = 0 Then
		FileDelete($sDest)
		Return False
	EndIf
	Return True
EndFunc   ;==>_Download
; ============================================================
;  ZIP entpacken via PowerShell Expand-Archive - zuverlaessiger
;  als Shell.Application, das auf modernen Windows-Systemen oft
;  gar nicht mehr greift (z.B. wenn 7-Zip/WinRAR die .zip-
;  Dateizuordnung uebernommen hat und Windows die Datei nicht mehr
;  als virtuellen Ordner behandelt).
; ============================================================
Func _UnZipPS($sZipFile, $sDestFolder)
	If Not FileExists($sZipFile) Then Return False
	If Not FileExists($sDestFolder) Then DirCreate($sDestFolder)
	Local $sPS1 = @TempDir & "\multidl_unzip_" & @AutoItPID & ".ps1"
	Local $sScript = "Expand-Archive -LiteralPath '" & StringReplace($sZipFile, "'", "''") & _
			"' -DestinationPath '" & StringReplace($sDestFolder, "'", "''") & "' -Force"
	FileDelete($sPS1)
	FileWrite($sPS1, $sScript)
	Local $iExit = RunWait('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' & $sPS1 & '"', "", @SW_HIDE)
	FileDelete($sPS1)
	Return $iExit = 0
EndFunc   ;==>_UnZipPS
; ============================================================
;  ZIP entpacken via Shell.Application (Fallback, falls PowerShell fehlt)
; ============================================================
Func _UnZip($sZipFile, $sDestFolder)
	If Not FileExists($sZipFile) Then Return SetError(1)
	If Not FileExists($sDestFolder) Then
		If Not DirCreate($sDestFolder) Then Return SetError(2)
	Else
		If Not StringInStr(FileGetAttrib($sDestFolder), "D") Then Return SetError(3)
	EndIf
	Local $oShell = ObjCreate("shell.application")
	If @error Or Not IsObj($oShell) Then Return SetError(5)
	Local $oZip = $oShell.NameSpace($sZipFile)
	If @error Or Not IsObj($oZip) Then Return SetError(6)
	Local $oItems = $oZip.items
	If @error Or Not IsObj($oItems) Then Return SetError(4)
	Local $iCount = $oItems.Count
	If $iCount = 0 Then Return SetError(4)
	Local $oNsDest = $oShell.NameSpace($sDestFolder)
	If @error Or Not IsObj($oNsDest) Then Return SetError(7)
	For $i = 0 To $iCount - 1
		Local $oFile = $oItems.Item($i)
		If IsObj($oFile) Then $oNsDest.CopyHere($oFile, 4 + 16)
	Next
EndFunc   ;==>_UnZip
; ============================================================
;  ffmpeg.exe aus ZIP holen
; ============================================================
Func _UnzipFFmpeg($sZip, $sDestDir)
	$g_sUnzipDebug = ""
	Local $sTmp = $sDestDir & "\ffmpeg_extracted", $s7zr = $sDestDir & "\7zr.exe", $s7za = $sDestDir & "\7za.exe", $sExtra = $sDestDir & "\7z_extra.7z"
	; alte/leere Reste eines vorherigen fehlgeschlagenen Versuchs entfernen
	If FileExists($sTmp) Then DirRemove($sTmp, 1)
	DirCreate($sTmp)
	; Zip-Download pruefen - unter 50 MB ist mit Sicherheit was schiefgelaufen
	If Not FileExists($sZip) Or FileGetSize($sZip) < 50000000 Then
		$g_sUnzipDebug = "Zip fehlt oder zu klein (" & (FileExists($sZip) ? FileGetSize($sZip) : 0) & " Bytes) - Download unvollstaendig."
		Return False
	EndIf
	If _IsWine() Then
		If Not FileExists($s7zr) Or FileGetSize($s7zr) < 100000 Then
			Local $s7zrURLFallback = _Get7zrURL()
			_Download($s7zrURLFallback, $s7zr)
			Do
				Sleep(100)
			Until FileExists($s7zr)
		EndIf
		; 7za.exe kann von einem frueheren abgebrochenen Lauf beschaedigt/leer liegen -
		; ohne Groessencheck wuerde das ewig wiederverwendet und die Extraktion
		; wuerde jedes Mal stillschweigend fehlschlagen
		If FileExists($s7za) And FileGetSize($s7za) < 400000 Then
			FileDelete($s7za)
		EndIf
		If Not FileExists($s7za) Then
			If Not FileExists($sExtra) Then
				Local $aTagFB = StringRegExp(_Get7zrURL(), "/download/([^/]+)/", 1)
				Local $sTagFB = (Not @error And UBound($aTagFB) >= 1) ? $aTagFB[0] : "26.00"
				Local $sVerFB = StringReplace($sTagFB, ".", "")
				_Download("https://github.com/ip7z/7zip/releases/download/" & $sTagFB & "/7z" & $sVerFB & "-extra.7z", $sExtra)
				Do
					Sleep(100)
				Until FileExists($sExtra)
			EndIf
			; Bei falschem/nicht-existentem Versions-Tag kommt eine winzige
			; 404-Fehlerseite statt des echten ~1-2 MB Archivs zurueck
			If FileGetSize($sExtra) < 200000 Then
				FileDelete($sExtra)
				$g_sUnzipDebug = "7z-extra.7z Download war fehlerhaft (falscher Versions-Tag?). Bitte 7za.exe manuell in " & $sDestDir & " ablegen."
				Return False
			EndIf
			Local $i7zaExit = RunWait('"' & $s7zr & '" e "' & $sExtra & '" 7za.exe -y', $sDestDir, @SW_HIDE)
			If $i7zaExit <> 0 Or Not FileExists($s7za) Then
				$g_sUnzipDebug = "7za.exe konnte nicht aus 7z-extra entpackt werden (Exitcode " & $i7zaExit & ")."
				Return False
			EndIf
		EndIf
		If FileExists($sExtra) Then FileDelete($sExtra)
		If FileExists($s7za) Then
			Local $iExit = RunWait('"' & $s7za & '" x "' & $sZip & '" -o"' & $sTmp & '" -y', $sDestDir, @SW_HIDE)
			If $iExit <> 0 Then
				$g_sUnzipDebug = "7za.exe Extraktion fehlgeschlagen, Exitcode " & $iExit & " (Zip: " & FileGetSize($sZip) & " Bytes, 7za: " & FileGetSize($s7za) & " Bytes)."
				Return False
			EndIf
			; RunWait kann unter Wine zurueckkommen bevor der Kind-Prozess die
			; Dateien wirklich fertig auf die Platte geschrieben hat -
			; zusaetzlich auf eine stabile ffmpeg.exe warten statt ihr blind zu vertrauen
			_WaitForFile($sTmp, "ffmpeg.exe", 60)
		Else
			$g_sUnzipDebug = "7za.exe fehlt nach Download-Versuch."
			Return False
		EndIf
	Else
		If Not _UnZipPS($sZip, $sTmp) Then
			; PowerShell fehlgeschlagen oder nicht vorhanden -> alte
			; Shell.Application-Methode als Fallback probieren
			_UnZip($sZip, $sTmp)
		EndIf
		_WaitForFile($sTmp, "ffmpeg.exe", 180)
	EndIf
	_FindAndCopyExe($sTmp, $sDestDir)
	If FileExists($sDestDir & "\ffmpeg.exe") Then
		DirRemove($sTmp, 1)
	Else
		If $g_sUnzipDebug = "" Then
			Local $iCount = _CountFilesRecursive($sTmp)
			$g_sUnzipDebug = "ffmpeg.exe wurde nach dem Entpacken nicht im Zip gefunden. " & _
					$iCount & " Datei(en) liegen zur Kontrolle noch in: " & $sTmp
		EndIf
	EndIf
	Return FileExists($sDestDir & "\ffmpeg.exe")
EndFunc   ;==>_UnzipFFmpeg
Func _CountFilesRecursive($sDir)
	Local $iCount = 0
	Local $hFind = FileFindFirstFile($sDir & "\*")
	If $hFind = -1 Then Return 0
	While 1
		Local $sName = FileFindNextFile($hFind)
		If @error Then ExitLoop
		If @extended Then
			$iCount += _CountFilesRecursive($sDir & "\" & $sName)
		Else
			$iCount += 1
		EndIf
	WEnd
	FileClose($hFind)
	Return $iCount
EndFunc   ;==>_CountFilesRecursive
; Prueft ob das Script unter Wine laeuft.
; Primaer: wine_get_version() in ntdll.dll - die von Wine offiziell dafuer
; vorgesehene Erkennungsfunktion, existiert auf JEDER Wine-Version unabhaengig
; von der Registry-Konfiguration (die Registry-Methode allein hat sich als
; unzuverlaessig erwiesen, manche Wine-Prefixe setzen den Key nicht).
Func _IsWine()
	Local $hDll = DllOpen("ntdll.dll")
	If $hDll <> -1 Then
		Local $aRet = DllCall($hDll, "str", "wine_get_version")
		DllClose($hDll)
		If Not @error And IsArray($aRet) Then Return True
	EndIf
	; Fallback: Registry-Key
	RegRead("HKLM\Software\Wine", "Version")
	If @error = 0 Then Return True
	Return False
EndFunc   ;==>_IsWine
; ============================================================
;  Wartet bis eine Datei rekursiv im Zielordner auftaucht UND
;  ihre Groesse sich nicht mehr aendert. Noetig weil
;  Shell.Application CopyHere() asynchron im Hintergrund laeuft -
;  bei grossen Zips (aktuell ~170 MB) reicht ein festes Sleep()
;  nicht mehr aus, die Kopie ist dann beim Weiterlaufen des Scripts
;  noch nicht fertig.
; ============================================================
Func _WaitForFile($sSearchDir, $sFileName, $iTimeoutSec = 120)
	Local $iElapsed = 0, $sFound = "", $iLastSize = -1, $iStableCount = 0
	Do
		$sFound = _FindFileRecursive($sSearchDir, $sFileName)
		If $sFound <> "" Then
			Local $iSize = FileGetSize($sFound)
			If $iSize = $iLastSize And $iSize > 0 Then
				$iStableCount += 1
				If $iStableCount >= 2 Then Return True
			Else
				$iStableCount = 0
			EndIf
			$iLastSize = $iSize
		EndIf
		Sleep(500)
		$iElapsed += 0.5
	Until $iElapsed >= $iTimeoutSec
	Return ($sFound <> "")
EndFunc   ;==>_WaitForFile
; Sucht rekursiv nach einer Datei mit gegebenem Namen, gibt vollen Pfad zurueck oder ""
Func _FindFileRecursive($sSearchDir, $sFileName)
	Local $hFind = FileFindFirstFile($sSearchDir & "\*")
	If $hFind = -1 Then Return ""
	Local $sResult = ""
	While 1
		Local $sName = FileFindNextFile($hFind)
		If @error Then ExitLoop
		Local $sFullPath = $sSearchDir & "\" & $sName
		If @extended Then
			$sResult = _FindFileRecursive($sFullPath, $sFileName)
			If $sResult <> "" Then ExitLoop
		Else
			If StringLower($sName) = StringLower($sFileName) Then
				$sResult = $sFullPath
				ExitLoop
			EndIf
		EndIf
	WEnd
	FileClose($hFind)
	Return $sResult
EndFunc   ;==>_FindFileRecursive
Func _FindAndCopyExe($sSearchDir, $sDestDir)
	Local $hFind = FileFindFirstFile($sSearchDir & "\*")
	If $hFind = -1 Then Return
	While 1
		Local $sName = FileFindNextFile($hFind)
		If @error Then ExitLoop
		Local $sFullPath = $sSearchDir & "\" & $sName
		If @extended Then
			_FindAndCopyExe($sFullPath, $sDestDir)
		Else
			If StringRegExp(StringLower($sName), "^(ffmpeg|ffprobe|ffplay)\.exe$") Then
				FileCopy($sFullPath, $sDestDir & "\" & $sName, 1)
			EndIf
		EndIf
	WEnd
	FileClose($hFind)
EndFunc   ;==>_FindAndCopyExe
; Progress-Bar Breite setzen (0-100) fuer Startup-Fenster
Func _ProgBar($hBar, $iPercent)
	GUICtrlSetPos($hBar, 16, 68, Int(388 * $iPercent / 100), 8)
EndFunc   ;==>_ProgBar
; Statuszeile setzen
Func _SetStatus($hLabel, $sText, $iColor)
	GUICtrlSetData($hLabel, "  " & _L($sText))
	GUICtrlSetColor($hLabel, $iColor)
EndFunc   ;==>_SetStatus
; ============================================================
;  Update: yt-dlp.exe + ffmpeg.exe neu laden
; ============================================================
Func _UpdateTools($hStatus, $hProgBar, $hProgLabel, $hProgPct)
	GUICtrlSetData($hBtnDownload, _L("Updating..."))
	_BtnBk($hBtnDownload, 0x3A0A0A)
	_UpdateToolsRun($hStatus, $hProgBar, $hProgLabel, $hProgPct)
	GUICtrlSetPos($hProgBar, 24, $PROG_Y, 0, $PROG_H)
	GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
	GUICtrlSetData($hBtnDownload, _L("Start"))
	$g_iStartState = -1 ; redraw the Start colour in the main loop
EndFunc   ;==>_UpdateTools
Func _UpdateToolsRun($hStatus, $hProgBar, $hProgLabel, $hProgPct)
	_SetStatus($hStatus, "Checking for updates...", 0x4FC3F7)
	GUICtrlSetData($hProgLabel, _L("Starting update..."))
	GUICtrlSetPos($hProgBar, 24, $PROG_Y, 0, $PROG_H)
	GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
	GUICtrlSetData($hProgPct, "")
	GUICtrlSetData($hProgLabel, _L("Updating yt-dlp.exe..."))
	Local $sURL1 = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
	Local $sTmp1 = $YTDLP_EXE & ".tmp"
	If _Download($sURL1, $sTmp1, $hProgBar, 0, 15, 24, $PROG_Y, 512, $PROG_H) Then
		FileDelete($YTDLP_EXE)
		FileMove($sTmp1, $YTDLP_EXE)
		GUICtrlSetData($hProgLabel, _L("yt-dlp.exe updated!"))
	Else
		FileDelete($sTmp1)
		_SetStatus($hStatus, "yt-dlp update failed!", 0xFF5252)
		Return
	EndIf
	GUICtrlSetData($hProgLabel, _L("Downloading ffmpeg... (~170 MB)"))
	Local $sURL2 = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
	Local $sZip = $BIN_DIR & "\ffmpeg_update.zip"
	If _Download($sURL2, $sZip, $hProgBar, 15, 85, 24, $PROG_Y, 512, $PROG_H) Then
		GUICtrlSetData($hProgLabel, _L("Unpacking ffmpeg.exe..."))
		GUICtrlSetPos($hProgBar, 24, $PROG_Y, Int(512 * 0.85), $PROG_H)
		FileDelete($BIN_DIR & "\ffmpeg.exe")
		FileDelete($BIN_DIR & "\ffprobe.exe")
		FileDelete($BIN_DIR & "\ffplay.exe")
		_UnzipFFmpeg($sZip, $BIN_DIR)
		FileDelete($sZip)
		If FileExists($FFMPEG_EXE) Then
			GUICtrlSetData($hProgLabel, _L("ffmpeg.exe updated!"))
		Else
			_SetStatus($hStatus, _L("ffmpeg update failed - unpack error! ") & $g_sUnzipDebug, 0xFF5252)
			Return
		EndIf
	Else
		FileDelete($sZip)
		_SetStatus($hStatus, "ffmpeg download failed!", 0xFF5252)
		Return
	EndIf
	; deno.exe (JS-Runtime fuer YouTube) - nicht fatal falls es fehlschlaegt
	GUICtrlSetData($hProgLabel, _L("Updating deno.exe..."))
	GUICtrlSetPos($hProgBar, 24, $PROG_Y, Int(512 * 0.85), $PROG_H)
	Local $sDenoZip = $BIN_DIR & "\deno_update.zip"
	Local $sDenoURL = "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip"
	Local $bDenoOK = False
	If _Download($sDenoURL, $sDenoZip, $hProgBar, 85, 98, 24, $PROG_Y, 512, $PROG_H) Then
		GUICtrlSetData($hProgLabel, _L("Unpacking deno.exe..."))
		FileDelete($DENO_EXE)
		If _IsWine() Then
			If FileExists($BIN_DIR & "\7za.exe") Then RunWait('"' & $BIN_DIR & '\7za.exe" x "' & $sDenoZip & '" -o"' & $BIN_DIR & '" -y', $BIN_DIR, @SW_HIDE)
		Else
			If Not _UnZipPS($sDenoZip, $BIN_DIR) Then _UnZip($sDenoZip, $BIN_DIR)
		EndIf
		If Not FileExists($DENO_EXE) Then
			Local $sFoundDeno = _FindFileRecursive($BIN_DIR, "deno.exe")
			If $sFoundDeno <> "" And $sFoundDeno <> $DENO_EXE Then FileMove($sFoundDeno, $DENO_EXE)
		EndIf
		$bDenoOK = FileExists($DENO_EXE)
	EndIf
	FileDelete($sDenoZip)
	GUICtrlSetPos($hProgBar, 24, $PROG_Y, 512, $PROG_H)
	GUICtrlSetBkColor($hProgBar, 0x00AA44)
	GUICtrlSetData($hProgPct, _L("Done!"))
	If $bDenoOK Then
		GUICtrlSetData($hProgLabel, _L("All tools updated!"))
		_SetStatus($hStatus, "Update complete!", 0x00AA44)
	Else
		GUICtrlSetData($hProgLabel, _L("yt-dlp + ffmpeg updated, deno failed."))
		_SetStatus($hStatus, "Update complete, but deno.exe could not be updated.", 0xFFAA00)
	EndIf
EndFunc   ;==>_UpdateToolsRun
; ============================================================
;  Prueft GitHub Releases auf eine neuere Version als $APP_VERSION.
;  Nicht fatal falls das fehlschlaegt (offline, Rate-Limit etc.) -
;  dann bleibt einfach kein Hinweis sichtbar.
; ============================================================
Func _CheckForUpdate($hUpdateBadge)
	Local $sJSON = BinaryToString(InetRead("https://api.github.com/repos/" & $GH_REPO & "/releases/latest", 1))
	If @error Or $sJSON = "" Then Return
	Local $aTag = StringRegExp($sJSON, '"tag_name"\s*:\s*"([^"]+)"', 1)
	If @error Or UBound($aTag) < 1 Then Return
	Local $sRemote = $aTag[0]
	If StringLeft($sRemote, 1) = "v" Or StringLeft($sRemote, 1) = "V" Then $sRemote = StringMid($sRemote, 2)
	If _CompareVersion($sRemote, $APP_VERSION) > 0 Then
		$g_sRemoteVer = $sRemote
		GUICtrlSetData($hUpdateBadge, ChrW(8593) & " Update: v" & $sRemote) ; U+2191: the old emoji arrow has no glyph under Wine/Linux
		GUICtrlSetState($hUpdateBadge, $GUI_SHOW)
	EndIf
EndFunc   ;==>_CheckForUpdate
; Vergleicht zwei Versionsstrings à la "7.1.0.2" nummerisch, Teil fuer Teil.
; Rueckgabe: 1 wenn $sA neuer, -1 wenn $sA aelter, 0 wenn gleich.
; ============================================================
;  Self update. MultiDL.exe starts a copy of itself (~MultiDL.exe) and exits, so the main file is
;  never locked while MultiDL runs. The update only has to replace MultiDL.exe and start it again.
; ============================================================
Func _ShowMsgId() ; registered window message: "show your window"
	Local $a = DllCall("user32.dll", "uint", "RegisterWindowMessageW", "wstr", "MultiDL_BrAiNee_ShowWindow")
	If @error Or Not IsArray($a) Then Return 0
	Return $a[0]
EndFunc   ;==>_ShowMsgId
Func _OtherInstance($bCreate) ; True = another MultiDL holds the mutex. $bCreate: take the mutex if it is free (kept until the process ends)
	Local $sName = "MultiDL_BrAiNee_SingleInstance"
	If $bCreate Then
		Local $aM = DllCall("kernel32.dll", "handle", "CreateMutexW", "ptr", 0, "bool", True, "wstr", $sName)
		If @error Or Not IsArray($aM) Then Return False
		Local $aE = DllCall("kernel32.dll", "dword", "GetLastError")
		If IsArray($aE) And $aE[0] = 183 Then ; ERROR_ALREADY_EXISTS
			DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aM[0])
			Return True
		EndIf
		Return False
	EndIf
	Local $aO = DllCall("kernel32.dll", "handle", "OpenMutexW", "dword", 0x00100000, "bool", False, "wstr", $sName)
	If @error Or Not IsArray($aO) Or Not $aO[0] Then Return False
	DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $aO[0])
	Return True
EndFunc   ;==>_OtherInstance
Func _SingleInstance($bCreate)
	If $g_bMultiInst Then Return
	Local $t = TimerInit(), $iWait = StringInStr($CmdLineRaw, "/updated") ? 10000 : 0 ; after an update the old instance is just closing
	While _OtherInstance($bCreate)
		If TimerDiff($t) >= $iWait Then
			_ShowRunningInstance()
			Exit
		EndIf
		Sleep(200)
	WEnd
EndFunc   ;==>_SingleInstance
Func _ShowRunningInstance() ; ask the running MultiDL to show itself (it may sit in the tray); if it can't be found we simply don't start another one
	Local $h = WinGetHandle($APP_TITLE)
	If @error Or Not $h Then Return
	Local $iPid = WinGetProcess($h)
	If $iPid > 0 Then DllCall("user32.dll", "bool", "AllowSetForegroundWindow", "dword", $iPid)
	Local $iMsg = _ShowMsgId()
	If $iMsg Then DllCall("user32.dll", "bool", "PostMessageW", "hwnd", $h, "uint", $iMsg, "wparam", 0, "lparam", 0)
EndFunc   ;==>_ShowRunningInstance
Func _OnShowMe($hWnd, $iMsg, $wParam, $lParam)
	$g_bShowReq = True
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_OnShowMe
Func _SelfRelaunch()
	If Not @Compiled Then Return
	If StringLeft(@ScriptName, 1) = "~" Then
		FileDelete($APP_DIR & "\" & StringTrimLeft(@ScriptName, 1) & ".new") ; leftover of an update
		Return
	EndIf
	DirCreate($BIN_DIR)
	Local $sCopy = $BIN_DIR & "\~" & @ScriptName, $i, $bOK = False
	For $i = 1 To 12 ; the copy can still be locked for a moment by the instance that just started the update
		If FileCopy(@ScriptFullPath, $sCopy, 1) Then
			$bOK = True
			ExitLoop
		EndIf
		Sleep(250)
	Next
	If Not $bOK Then Return ; no write access / copy in use -> simply run from here
	DllCall("user32.dll", "bool", "AllowSetForegroundWindow", "dword", -1) ; the new process may take the focus (else the first click only activates the window)
	Run('"' & $sCopy & '" ' & $CmdLineRaw, $APP_DIR)
	Exit
EndFunc   ;==>_SelfRelaunch
Func _SelfUpdate() ; click on the update badge
	Local $sName = StringTrimLeft(@ScriptName, 1), $sMain = $APP_DIR & "\" & $sName, $sTmp = $sMain & ".new"
	If Not @Compiled Or StringLeft(@ScriptName, 1) <> "~" Then
		ShellExecute("https://github.com/" & $GH_REPO & "/releases/latest") ; not started through the copy -> just open the release page
		Return
	EndIf
	If MsgBox(36, $APP_TITLE, _L("Update to v") & $g_sRemoteVer & _L(" now?") & @CRLF & _L("MultiDL restarts afterwards.")) <> 6 Then Return
	FileDelete($sTmp)
	If Not _Download("https://github.com/" & $GH_REPO & "/releases/latest/download/" & $sName, $sTmp) Or FileGetSize($sTmp) < 200000 Or FileRead($sTmp, 2) <> "MZ" Then
		FileDelete($sTmp)
		MsgBox(16, $APP_TITLE, _L("Update download failed.") & @CRLF & _L("(Release needs an asset named ") & $sName & ")")
		Return
	EndIf
	If Not FileMove($sTmp, $sMain, 1) Then
		FileDelete($sTmp)
		MsgBox(16, $APP_TITLE, _L("Could not replace ") & $sName & ".")
		Return
	EndIf
	DllCall("user32.dll", "bool", "AllowSetForegroundWindow", "dword", -1)
	Run('"' & $sMain & '" /updated', $APP_DIR)
	Exit
EndFunc   ;==>_SelfUpdate
Func _CompareVersion($sA, $sB)
	Local $aA = StringSplit($sA, ".", 2)
	Local $aB = StringSplit($sB, ".", 2)
	Local $iMax = UBound($aA)
	If UBound($aB) > $iMax Then $iMax = UBound($aB)
	For $i = 0 To $iMax - 1
		Local $iA = ($i < UBound($aA)) ? Number($aA[$i]) : 0
		Local $iB = ($i < UBound($aB)) ? Number($aB[$i]) : 0
		If $iA > $iB Then Return 1
		If $iA < $iB Then Return -1
	Next
	Return 0
EndFunc   ;==>_CompareVersion
Func _Get7zrURL()
	Local $sAPI = "https://api.github.com/repos/ip7z/7zip/releases/latest"
	Local $sJSON = BinaryToString(InetRead($sAPI, 1))
	Local $aTag = StringRegExp($sJSON, '"tag_name"\s*:\s*"([^"]+)"', 1)
	If @error Or UBound($aTag) < 1 Then Return "https://github.com/ip7z/7zip/releases/download/26.00/7zr.exe"
	Local $sTag = $aTag[0]
	Local $sVer = StringReplace($sTag, ".", "")
	Return "https://github.com/ip7z/7zip/releases/download/" & $sTag & "/7zr.exe"
EndFunc   ;==>_Get7zrURL
; ------------------------------------------------------------
;  True for any suno.com/suno.ai link that isn't already
;  a direct cdn url.
; ------------------------------------------------------------
Func _IsSunoURL($sURL)
	Return StringRegExp($sURL, "(?i)^https?://(www\.)?suno\.(com|ai)/")
EndFunc   ;==>_IsSunoURL
; ------------------------------------------------------------
;  Pull the clip uuid out of a suno.com/song/<uuid> (or any
;  other suno url shape that carries the uuid directly).
; ------------------------------------------------------------
Func _SunoClipId($sURL)
	Local $aM = StringRegExp($sURL, "(?i)([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})", 1)
	If IsArray($aM) Then Return $aM[0]
	Return ""
EndFunc   ;==>_SunoClipId
; ------------------------------------------------------------
;  suno.com/song/<uuid>  ->  https://cdn1.suno.ai/<uuid>.mp4
;  Returns the original url unchanged if no id is found (e.g.
;  a suno.com/s/<short> share link - those need resolving first,
;  not handled here).
; ------------------------------------------------------------
Func _SunoRewriteURL($sURL)
	Local $sId = _SunoClipId($sURL)
	If $sId = "" Then Return $sURL
	Return "https://cdn1.suno.ai/" & $sId & ".mp4"
EndFunc   ;==>_SunoRewriteURL
; ------------------------------------------------------------
;  Der Songname steht NICHT auf der suno.com-Seite selbst drin
;  (die rendert alles per JS), sondern kommt sauber als JSON von
;  Sunos eigener Clip-API - kein IE/WebView noetig, ganz normaler
;  InetRead genau wie bei _Get7zrURL() weiter oben.
;  Gibt "" zurueck wenn was schiefgeht (kein Internet, 404, ...).
; ------------------------------------------------------------
Func _SunoClipTitle($sId)
	If $sId = "" Then Return ""
	Local $sAPI = "https://studio-api.prod.suno.com/api/clip/" & $sId
	Local $bData = InetRead($sAPI, 1)
	If @error Then Return ""
	Local $sJSON = BinaryToString($bData, 4)
	Local $aTitle = StringRegExp($sJSON, '"title"\s*:\s*"((?:[^"\\]|\\.)*)"', 1)
	If @error Or UBound($aTitle) < 1 Then Return ""
	Local $sName = _SanitizeFilename(_JsonUnescape($aTitle[0]))
	If $sName = "" Then $sName = "suno_" & StringLeft($sId, 8) ; title was only emoji/symbols -> still a safe, unique file name
	Return $sName
EndFunc   ;==>_SunoClipTitle
; ------------------------------------------------------------
;  JSON string -> real text (\uXXXX incl. emoji pairs, \n, \", \\ ...).
;  The old version turned ’ into "u2019".
; ------------------------------------------------------------
Func _JsonUnescape($s)
	If Not StringInStr($s, "\") Then Return $s
	Local $sOut = "", $i = 1, $n = StringLen($s), $c
	While $i <= $n
		$c = StringMid($s, $i, 1)
		If $c <> "\" Or $i = $n Then
			$sOut &= $c
			$i += 1
			ContinueLoop
		EndIf
		$c = StringMid($s, $i + 1, 1)
		If $c == "u" And StringRegExp(StringMid($s, $i + 2, 4), "^[0-9A-Fa-f]{4}$") Then
			$sOut &= ChrW(Dec(StringMid($s, $i + 2, 4)))
			$i += 6
		ElseIf $c == "n" Or $c == "r" Or $c == "t" Then
			$sOut &= " "
			$i += 2
		Else
			$sOut &= $c ; \" \\ \/
			$i += 2
		EndIf
	WEnd
	Return $sOut
EndFunc   ;==>_JsonUnescape
; ------------------------------------------------------------
;  Title -> SAFE file name (works on Windows and under Wine/Linux).
;  Whitelist instead of blacklist: letters (incl. umlauts/accents), digits and a few
;  harmless marks stay; typographic quotes/dashes are mapped; everything else
;  (emoji, symbols, CJK, control chars, % ^ $ ~ ; = @ { } * ? < > ...) is dropped.
;  "%" matters most: yt-dlp would treat it as part of the -o template.
;  Returns "" if nothing is left (the caller then uses the clip id).
; ------------------------------------------------------------
Func _SanitizeFilename($sName)
	Local $sOut = "", $i, $ch, $c
	For $i = 1 To StringLen($sName)
		$ch = StringMid($sName, $i, 1)
		$c = AscW($ch)
		Select
			Case $c = 32 Or ($c >= 48 And $c <= 57) Or ($c >= 65 And $c <= 90) Or ($c >= 97 And $c <= 122)
				$sOut &= $ch ; letters, digits, space
			Case $c = 33 Or $c = 35 Or $c = 39 Or $c = 40 Or $c = 41 Or $c = 43 Or $c = 44 Or $c = 45 Or $c = 46 Or $c = 91 Or $c = 93 Or $c = 95
				$sOut &= $ch ; ! # ' ( ) + , - . [ ] _
			Case $c >= 192 And $c <= 591 And $c <> 215 And $c <> 247
				$sOut &= $ch ; accented Latin letters (umlauts ...)
			Case $c = 160 Or $c = 8239 Or ($c >= 8192 And $c <= 8202)
				$sOut &= " " ; exotic spaces
			Case $c = 34 Or $c = 96 Or $c = 180 Or ($c >= 8216 And $c <= 8223)
				$sOut &= "'" ; quotes
			Case $c = 47 Or $c = 92 Or $c = 124 Or $c = 58 Or $c = 8211 Or $c = 8212 Or $c = 8722
				$sOut &= "-" ; / \ | : and dashes
			Case $c = 38
				$sOut &= " and "
			Case $c = 8230
				$sOut &= "..."
		EndSelect
	Next
	$sOut = StringRegExpReplace($sOut, "\s+", " ")
	$sOut = StringRegExpReplace($sOut, "-{2,}", "-")
	$sOut = StringRegExpReplace($sOut, "^[\s.\-]+|[\s.\-]+$", "") ; no leading/trailing space, dot or dash (Windows dislikes trailing dots/spaces)
	If StringLen($sOut) > 100 Then $sOut = StringRegExpReplace(StringLeft($sOut, 100), "[\s.\-]+$", "")
	If StringRegExp($sOut, "(?i)^(con|prn|aux|nul|com\d|lpt\d)(\..*)?$") Then $sOut = "_" & $sOut ; reserved device names
	Return $sOut
EndFunc   ;==>_SanitizeFilename
; ============================================================
; BrAiNPlay embedded engine (CURRENT brainplay(5).au3 core)
Func _EscPressed() ; True while Esc is down (or was just tapped)
	Local $r = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 0x1B)
	Return IsArray($r) And BitAND($r[0], 0x8001) <> 0
EndFunc   ;==>_EscPressed
Func BP_Mci($sCMD)
	Local $t = DllStructCreate("wchar[256]")
	Local $r = DllCall("winmm.dll", "dword", "mciSendStringW", "wstr", $sCMD, "ptr", DllStructGetPtr($t), "uint", 255, "ptr", 0)
	$BP_iErr = @error ? -1 : $r[0]
	Return DllStructGetData($t, 1)
EndFunc   ;==>BP_Mci
Func BP_Play($i)
	If $i < 0 Or $i >= UBound($BP_aPl) Then Return
	$BP_fFixed = False
	Local $ok = BP_Open($BP_aPl[$i])
	If Not $ok And StringRight($BP_aPl[$i], 4) = ".mp3" Then $ok = BP_Retry($i)
	$BP_iCur = $i
	If $BP_aLn[$i] <= 0 Then
		Local $bpL = BP_MP3_GetLengthSec($BP_aPl[$i])
		If $bpL > 0 Then
			$BP_aLn[$i] = $bpL
			BP_ItemSet($i)
		EndIf
	EndIf
	If $BP_fFF And $BP_aLn[$i] <= 0 Then ; ffplay video without a known length (Wine has no Explorer lookup) -> ffprobe
		Local $bpD = BP_FFLen($BP_aPl[$i])
		If $bpD > 0 Then
			$BP_aLn[$i] = $bpD
			BP_ItemSet($i)
		EndIf
	EndIf
	$BP_iLen = $BP_aLn[$i] ; Explorer length (same as in the list); MCI's own length is only an estimate for many mp3s
	If $BP_iLen <= 0 Then $BP_iLen = Number(BP_Mci("status bp length")) / 1000
	$BP_tCmd = TimerInit()
	$BP_tStart = TimerInit()
	$BP_iOff = 0
	$BP_tRun = TimerInit()
	$BP_fPlay = True
	$BP_fPause = False
	BP_Apply()
	$BP_fVid = BP_IsVid($BP_aPl[$i]) And ($BP_fEmb Or $BP_fFF) And $ok ; TV button / window only if the video really sits in our window
	$BP_iVSz = 0
	$BP_sWin = "" ; (window mode: size + center the window again for this video)
	BP_VidApply()
	$BP_sNow = BP_Tags($BP_aPl[$i])
	GUICtrlSetData($BP_bPlay, "||")
	GUICtrlSetData($BP_lblNow, $BP_sNow)
	WinSetTitle($BP_hVid, "", $BP_sNow) ; (window mode shows it in the title bar)
	$BP_iZoom = 100
	BP_Tip()
	GUICtrlSendMsg($BP_lst, $LB_SETCURSEL, $i, 0)
	BP_Wave($BP_aPl[$i])
	BP_Seg(0)
EndFunc   ;==>BP_Play
Func BP_FFKill()
	If $BP_pFF Then
		If ProcessExists($BP_pFF) Then ProcessClose($BP_pFF)
		$BP_pFF = 0
	EndIf
	$BP_fFF = False
EndFunc   ;==>BP_FFKill
Func BP_FFStart($f, $iSs = 0) ; video through ffplay (own window): used under Wine/Linux, or when MCI and WMP can't play it. $iSs = start second (seek / resume)
	BP_FFKill()
	Local $c = '"' & $FFPLAY_EXE & '" -autoexit -loglevel error -window_title "MultiDL BrAiNPlay" -volume ' & $BP_iVol
	If $iSs > 0 Then $c &= ' -ss ' & Int($iSs)
	If $BP_iBal <> 0 Then ; ffplay has no balance option -> pan filter (mono sources are upmixed to stereo first)
		Local $gl = $BP_iBal > 0 ? (100 - $BP_iBal) / 100 : 1, $gr = $BP_iBal < 0 ? (100 + $BP_iBal) / 100 : 1
		$c &= ' -af "aformat=channel_layouts=stereo,pan=stereo|c0=' & StringFormat("%.2f", $gl) & '*c0|c1=' & StringFormat("%.2f", $gr) & '*c1"'
	EndIf
	$BP_iFFVol = $BP_iVol
	$BP_iFFBal = $BP_iBal
	If Not $BP_fVidOn Then
		$c &= ' -nodisp' ; VIDEO OFF: sound only
	ElseIf $BP_fFull Then
		$c &= ' -fs'
	EndIf
	$BP_pFF = Run($c & ' "' & $f & '"', $APP_DIR)
	If $BP_pFF = 0 Then Return False
	_HideWineConsole() ; the ffplay console window shows up under Windows too
	$BP_fFF = True
	BP_Log("video via ffplay: " & $f)
	Return True
EndFunc   ;==>BP_FFStart
Func BP_FFKeys() ; F / V typed while the ffplay window has the focus (polled every ~30 ms): same keys as in every other play mode, done by us (restart at the same second)
	Static $bPF = False, $bPV = False
	Local $aF = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 0x46), $aV = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 0x56)
	Local $bF = (IsArray($aF) And BitAND($aF[0], 0x8000) <> 0), $bV = (IsArray($aV) And BitAND($aV[0], 0x8000) <> 0)
	Local $bEdgeF = ($bF And Not $bPF), $bEdgeV = ($bV And Not $bPV)
	$bPF = $bF
	$bPV = $bV
	If Not ($bEdgeF Or $bEdgeV) Then Return
	Local $hA = WinGetHandle("[ACTIVE]")
	If Not $hA Then Return
	If Not (WinGetProcess($hA) = $BP_pFF Or WinActive("[TITLE:MultiDL BrAiNPlay; CLASS:SDL_app]")) Then Return
	If $bEdgeF Then
		BP_VidKey("f") ; fullscreen <-> window
	ElseIf $bEdgeV Then
		BP_ToggleVid() ; picture on / off
	EndIf
EndFunc   ;==>BP_FFKeys
Func BP_FFTick() ; ffplay housekeeping (called from BP_Tick)
	If $BP_pFF And Not $BP_fPause And Not $BP_iDrag And $BP_tFFApply And TimerDiff($BP_tFFApply) > 400 Then
		$BP_tFFApply = 0
		If $BP_iVol <> $BP_iFFVol Or $BP_iBal <> $BP_iFFBal Then BP_FFRestart() ; volume / balance changed
	EndIf
EndFunc   ;==>BP_FFTick
Func BP_FFLen($f) ; duration in seconds via ffprobe (0 = unknown)
	Local $sProbe = $BIN_DIR & "\ffprobe.exe"
	If Not FileExists($sProbe) Then Return 0
	Local $h = Run('"' & $sProbe & '" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "' & $f & '"', $APP_DIR, @SW_HIDE, 2)
	If Not $h Then Return 0
	Local $o = "", $t = TimerInit()
	While ProcessExists($h) And TimerDiff($t) < 5000
		$o &= StdoutRead($h)
		Sleep(20)
	WEnd
	$o &= StdoutRead($h)
	Return Number(StringStripWS($o, 8))
EndFunc   ;==>BP_FFLen
Func BP_Open($f) ; open + play, True if no error. MCI first; a video MCI can't play falls back to the Windows Media Player control, then to ffplay
	BP_FFKill() ; a previous ffplay video ends with the track change
	If $BP_fWmp Then $BP_oWMP.controls.stop()
	$BP_fWmp = False
	If $BP_idWMP Then GUICtrlSetState($BP_idWMP, $GUI_HIDE) ; hide the old WMP picture while MCI plays
	If IsObj($BP_oWMP) Then $BP_oWMP.fullScreen = False ; leave WMP's own fullscreen (it is entered again for the next WMP video if wanted)
	$BP_fWFS = False ; ... and that is not the user leaving it (would switch the video off)
	BP_Mci("close bp")
	$BP_fEmb = False
	Local $vid = BP_IsVid($f), $c = 'open "' & $f & '" alias bp', $e
	If $vid And FileExists($FFPLAY_EXE) And ($BP_fWine Or StringRight($f, 15) = "_watch_live.mp4") Then Return BP_FFStart($f) ; (the growing live file always goes through ffplay) ; Wine/Linux: MCI and WMP have no video support -> ffplay
	If $vid Then
		BP_Log("video via MCI: " & $f)
		Sleep(60) ; let MCI finish tearing down the previous video window
		BP_Mci($c & " type mpegvideo parent " & Number(String($BP_hVid)) & " style child")
		If $BP_iErr Then
			BP_Log("open (embedded) failed: " & BP_MciErr($BP_iErr) & " | " & $f & " -> retry")
			BP_Mci("close bp")
			Sleep(250)
			BP_Mci($c & " type mpegvideo parent " & Number(String($BP_hVid)) & " style child") ; second try before giving up on the embedded window
			If $BP_iErr Then
				BP_Log("open (embedded) failed again: " & BP_MciErr($BP_iErr))
				BP_Mci("close bp")
				BP_Mci($c & " type mpegvideo")
			Else
				$BP_fEmb = True
			EndIf
		Else
			$BP_fEmb = True
		EndIf
	Else
		BP_Mci($c)
	EndIf
	$e = $BP_iErr
	If $e Then
		BP_Log("open failed: " & BP_MciErr($e) & " | " & $f)
	Else
		BP_Mci("set bp time format milliseconds")
		BP_Mci("play bp")
		$e = $BP_iErr
		If $e Then BP_Log("play failed: " & BP_MciErr($e) & " | " & $f)
	EndIf
	If $e And $vid Then ; MCI can't do this video -> Windows Media Player as backup
		BP_Mci("close bp")
		If BP_WmpInit() Then Return BP_OpenWmp($f)
		If FileExists($FFPLAY_EXE) Then Return BP_FFStart($f) ; no WMP either -> ffplay
	EndIf
	Return Not $e
EndFunc   ;==>BP_Open
Func BP_WmpInit() ; create the WMP control inside the video window on first use; False if WMP is not available
	If $BP_fWine Then Return False ; Windows Media Player ActiveX is not usable under Wine
	If $BP_iWInit Then Return IsObj($BP_oWMP)
	$BP_iWInit = 1
	$BP_oWMP = ObjCreate("WMPlayer.OCX")
	If Not IsObj($BP_oWMP) Then
		BP_Log("WMP: ObjCreate failed")
		Return False
	EndIf
	GUISwitch($BP_hVid) ; the control must be created while the video window is the current GUI
	$BP_idWMP = GUICtrlCreateObj($BP_oWMP, 0, 0, $BP_iWw, $BP_iWh) ; dock size; never resized (WMP does its own fullscreen)
	GUICtrlSetResizing($BP_idWMP, $GUI_DOCKALL)
	GUISwitch($BP_hMain)
	$BP_oWMP.uiMode = "none"
	$BP_oWMP.stretchToFit = True ; scale the video to the window (default: 100% size, cropped)
	$BP_oWMP.enableContextMenu = False
	$BP_oWMP.settings.enableErrorDialogs = False
	BP_Log("WMP control created, ctrl id " & $BP_idWMP)
	Return True
EndFunc   ;==>BP_WmpInit
Func BP_OpenWmp($f) ; video through the Windows Media Player control in the video window (it starts by itself)
	$BP_fWmp = True
	$BP_fEmb = True
	$BP_iWSt = -1
	$BP_fWFS = False
	GUICtrlSetState($BP_idWMP, $GUI_SHOW)
	BP_Log("video via WMP (window wanted=" & $BP_fVidOn & ", ctrl id " & $BP_idWMP & "): " & $f)
	$BP_oWMP.settings.volume = $BP_iVol
	$BP_oWMP.settings.balance = $BP_iBal
	$BP_oWMP.URL = $f
	Return True
EndFunc   ;==>BP_OpenWmp
Func BP_Retry($i) ; some mp3s are refused/skipped by MCI until the junk before the real MPEG stream (ID3v2, scene header ...) is cut -> play a cleaned temp copy
	BP_Mci("close bp") ; release a previous temp copy
	Local $g = BP_SoundPlayFixMP3($BP_aPl[$i], $BP_sTmp)
	If $g = "" Or $g = $BP_aPl[$i] Then Return False ; nothing to cut
	$BP_fFixed = True
	$BP_tCmd = TimerInit()
	$BP_tStart = TimerInit()
	$BP_iOff = 0
	$BP_tRun = TimerInit()
	Local $ok = BP_Open($g)
	If $ok Then BP_Apply()
	Return $ok
EndFunc   ;==>BP_Retry
Func BP_PlayPause()
	If $BP_fPlay Then
		$BP_fPause = Not $BP_fPause
		If $BP_fWmp Then
			If $BP_fPause Then
				$BP_oWMP.controls.pause()
			Else
				$BP_oWMP.controls.play()
			EndIf
		ElseIf $BP_pFF Or $BP_fFF Then ; ffplay can't be paused from outside: pause = stop it, resume = start again at the same second
			If $BP_fPause Then
				BP_FFKill()
				$BP_fFF = True ; (still an ffplay track, just not running)
			Else
				BP_FFStart($BP_aPl[$BP_iCur], $BP_iOff)
				$BP_tCmd = TimerInit()
			EndIf
		Else
			BP_Mci($BP_fPause ? "pause bp" : "resume bp")
		EndIf
		If $BP_fPause Then
			$BP_iOff += TimerDiff($BP_tRun) / 1000
		Else
			$BP_tRun = TimerInit()
		EndIf
		GUICtrlSetData($BP_bPlay, $BP_fPause ? ChrW(9658) : "||")
	Else
		Local $s = GUICtrlSendMsg($BP_lst, $LB_GETCURSEL, 0, 0)
		BP_Play($s < 0 ? 0 : $s)
	EndIf
EndFunc   ;==>BP_PlayPause
Func BP_Pos() ; own clock (MCI's position/length are unreliable for some mp3s): offset set on play/seek + time since
	If $BP_fWmp Then Return Number($BP_oWMP.controls.currentPosition) ; WMP knows the real position
	Return $BP_fPause ? $BP_iOff : $BP_iOff + TimerDiff($BP_tRun) / 1000
EndFunc   ;==>BP_Pos
Func BP_Seek($f) ; $f = 0..1
	If Not $BP_fPlay Or $BP_iLen <= 0 Then Return
	If $BP_fWmp Then
		$BP_oWMP.controls.currentPosition = $f * $BP_iLen
		$BP_oWMP.controls.play()
		$BP_tCmd = TimerInit()
		$BP_fPause = False
		GUICtrlSetData($BP_bPlay, "||")
		BP_Tick()
		Return
	EndIf
	If $BP_fFF Then ; ffplay: restart at the new second
		BP_FFStart($BP_aPl[$BP_iCur], $f * $BP_iLen)
		$BP_tCmd = TimerInit()
		$BP_iOff = $f * $BP_iLen
		$BP_tRun = TimerInit()
		$BP_fPause = False
		GUICtrlSetData($BP_bPlay, "||")
		BP_Tick()
		Return
	EndIf
	Local $l = Number(BP_Mci("status bp length"))
	If $l <= 0 Then Return
	BP_Mci("seek bp to " & Int($f * $l)) ; fraction of MCI's own timeline
	BP_Mci("play bp")
	$BP_tCmd = TimerInit()
	$BP_iOff = $f * $BP_iLen
	$BP_tRun = TimerInit()
	$BP_fPause = False
	GUICtrlSetData($BP_bPlay, "||")
	BP_Tick()
EndFunc   ;==>BP_Seek
Func BP_Skip($d) ; seek relative, seconds
	If Not $BP_fPlay Or $BP_iLen <= 0 Then Return
	BP_Seek(_Min(_Max((BP_Pos() + $d) / $BP_iLen, 0), 0.999))
EndFunc   ;==>BP_Skip
Func BP_Stop()
	BP_FFKill()
	If $BP_fWmp Then $BP_oWMP.controls.stop()
	$BP_fWmp = False
	If $BP_idWMP Then GUICtrlSetState($BP_idWMP, $GUI_HIDE)
	If IsObj($BP_oWMP) Then $BP_oWMP.fullScreen = False
	BP_Mci("close bp")
	$BP_fPlay = False
	$BP_fPause = False
	$BP_sNow = ""
	BP_VidApply()
	GUICtrlSetData($BP_bPlay, ChrW(9658))
	GUICtrlSetData($BP_lblNow, _L("stopped"))
	If Not $BP_bPlayerMode Then BP_MediaKeys(False)
	WinSetTitle($BP_hVid, "", "BrAiNPlay Video")
	BP_Tip()
	GUICtrlSetData($BP_lblTime, "00:00 / --:--")
	BP_Wave("")
	BP_Seg(0)
EndFunc   ;==>BP_Stop
Func BP_Next($d)
	Local $c = UBound($BP_aPl)
	If $c Then BP_Play($BP_fShuf ? Random(0, $c - 1, 1) : Mod($BP_iCur + $d + $c, $c))
EndFunc   ;==>BP_Next
Func BP_Prev() ; hotkey callbacks must be parameterless
	BP_Next(-1)
EndFunc   ;==>BP_Prev
Func BP_HkNext()
	BP_Next(1)
EndFunc   ;==>BP_HkNext
Func BP_Tick()
	If $BP_tNote And TimerDiff($BP_tNote) > 2500 Then ; temporary note over, header shows the track again
		$BP_tNote = 0
		GUICtrlSetData($BP_lblNow, $BP_fPlay ? $BP_sNow : _L("stopped"))
	EndIf
	BP_FillLen()
	If $BP_fPlay And $BP_fVid And $BP_fVidOn And Not $BP_fTray And Not $BP_fFF And TimerDiff($BP_tStart) > 500 And Not BitAND(WinGetState($BP_hVid), 2) Then ; video is wanted but its window is gone (e.g. after a track change) -> bring it back
		BP_Log("video window was hidden, showing it again")
		BP_VidApply()
	EndIf
	If $BP_fFF Then BP_FFTick()
	If Not $BP_fPlay Or $BP_fPause Then Return
	Local $m, $ended
	If $BP_fWmp Then ; playState: 3 playing, 2 paused, 6/7/9 loading, 8 ended, 1 stopped, 10 ready
		$m = Number($BP_oWMP.playState)
		If $m <> $BP_iWSt Then
			$BP_iWSt = $m
			BP_Log("wmp state " & $m & " | pos " & Round(Number($BP_oWMP.controls.currentPosition), 1) & " " & BP_WmpErr())
		EndIf
		$ended = ($m = 8 Or $m = 1 Or $m = 10 Or $m = 0)
	ElseIf $BP_fFF Then
		$ended = Not ProcessExists($BP_pFF)
	Else
		$m = BP_Mci("status bp mode")
		$ended = ($m <> "playing")
	EndIf
	If $ended And $BP_fFF And $BP_iLen > 0 And (TimerDiff($BP_tStart) > 5000 Or $BP_iOff > 0) And TimerDiff($BP_tCmd) > 3000 And BP_Pos() < $BP_iLen - 3 Then
		BP_Stop() ; ffplay was closed before the end (ESC / window X) -> stop, don't jump to the next track
		Return
	EndIf
	If $ended And TimerDiff($BP_tCmd) > (BP_IsVid($BP_aPl[$BP_iCur]) ? 3000 : 600) Then ; track finished (or failed to open)
		Local $bad = TimerDiff($BP_tStart) < 5000 And $BP_iOff = 0
		If $bad Then BP_Log("stopped early (" & ($BP_fWmp ? "wmp state=" & $m & " " & BP_WmpErr() : "mode=" & $m) & "): " & $BP_aPl[$BP_iCur])
		If Not $BP_fFixed And $BP_iOff = 0 And TimerDiff($BP_tStart) < 3000 And StringRight($BP_aPl[$BP_iCur], 4) = ".mp3" Then ; died right at the start: try without ID3v2 tag
			If BP_Retry($BP_iCur) Then Return
		EndIf
		If $BP_fShuf Or $BP_fLoop Or $BP_iCur < UBound($BP_aPl) - 1 Then
			BP_Next(1)
		Else
			BP_Stop()
			If $bad Then GUICtrlSetData($BP_lblNow, (BP_IsVid($BP_aPl[$BP_iCur]) And Not IsObj($BP_oWMP)) ? _L("video needs Windows Media Player (Legacy) or a codec pack") : _L("can't play this file"))
		EndIf
		Return
	EndIf
	If $BP_fVid And Not $BP_fFF And $BP_iVSz = 0 And TimerDiff($BP_tStart) > 800 And (Not $BP_fWmp Or $m = 3) Then ; video size is known by now (WMP: playing) -> fit it / WMP: go fullscreen
		$BP_iVSz = 1
		BP_VideoSize()
		If $BP_fFull And Not $BP_fWmp Then BP_Osd($BP_sNow, 4000) ; track title over the fullscreen video (WMP: when it enters fullscreen)
		If $BP_fWmp Then BP_Log("wmp audio languages: " & Number($BP_oWMP.controls.audioLanguageCount))
	EndIf
	If $BP_fWmp And Not $BP_fFull And $BP_fVidOn And $BP_iVSz >= 1 And TimerDiff($BP_tStart) < 8000 Then BP_WmpFit() ; WMP reports the picture size late (first it may still show the previous video's) -> follow it for the first seconds
	If $BP_fWmp And $BP_iLen <= 0 Then ; length unknown from Explorer -> ask WMP
		Local $oM = $BP_oWMP.currentMedia
		If IsObj($oM) Then $BP_iLen = Number($oM.duration)
	EndIf
	Local $s = BP_Pos()
	If $BP_iLen > 0 Then $s = _Min($s, $BP_iLen)
	If $BP_bPlayerMode Then GUICtrlSetData($BP_lblTime, BP_T($s) & " / " & ($BP_iLen ? BP_T($BP_iLen) : "--:--")) ; (hidden label sits over the last line of the link field: updating it there made it flicker)
	Local $k = $BP_iLen ? _Min(Int($s / $BP_iLen * $BP_N), $BP_N) : 0
	If $k <> $BP_iLit Then BP_Seg($k)
EndFunc   ;==>BP_Tick
Func BP_Seg($k)
	If Not $BP_bPlayerMode Then Return ; hidden controls stay untouched (a color change can make them show through the download view)
	For $i = 0 To $BP_N - 1
		GUICtrlSetBkColor($BP_aSeg[$i], $i < $k ? $BP_ACC : $BP_DIM)
	Next
	$BP_iLit = $k
EndFunc   ;==>BP_Seg
; ================= volume / balance =================
Func BP_Drag()
	Local $c = GUIGetCursorInfo($BP_hMain)
	If Not IsArray($c) Then Return
	If Not $c[2] Then ; mouse released
		$BP_iDrag = 0
		Return
	EndIf
	If $BP_iDrag = 1 Then
		$BP_iVol = Int(_Min(_Max(($c[0] - $BP_VX) / $BP_VW * 100, 0), 100))
	Else
		$BP_iBal = Int(_Min(_Max(($c[0] - $BP_BX) / $BP_BW * 200 - 100, -100), 100))
		If Abs($BP_iBal) < 8 Then $BP_iBal = 0 ; snap to center
	EndIf
	BP_Apply()
EndFunc   ;==>BP_Drag
Func BP_Vol($d)
	$BP_iVol = Int(_Min(_Max($BP_iVol + $d, 0), 100))
	BP_Apply()
EndFunc   ;==>BP_Vol
Func BP_Mute()
	If $BP_iVol > 0 Then
		$BP_iPre = $BP_iVol
		$BP_iVol = 0
	Else
		$BP_iVol = $BP_iPre
	EndIf
	BP_Apply()
EndFunc   ;==>BP_Mute
Func BP_Apply()
	Local $v = $BP_iVol * 10, $l = $v, $r = $v, $ok = True
	If $BP_iBal > 0 Then $l = $v * (100 - $BP_iBal) / 100
	If $BP_iBal < 0 Then $r = $v * (100 + $BP_iBal) / 100
	If $BP_fPlay Then
		If $BP_fFF Then
			$BP_tFFApply = TimerInit() ; ffplay can't change volume/balance while running -> BP_Tick restarts it at the same second (debounced)
		ElseIf $BP_fWmp Then
			$BP_oWMP.settings.volume = $BP_iVol
			$BP_oWMP.settings.balance = $BP_iBal
		ElseIf $BP_iBal = 0 Then
			BP_Mci("setaudio bp volume to " & Int($v))
		Else
			BP_Mci("setaudio bp left volume to " & Int($l))
			If $BP_iErr Then ; device ignores balance -> volume only
				$ok = False
				BP_Mci("setaudio bp volume to " & Int($v))
			Else
				BP_Mci("setaudio bp right volume to " & Int($r))
			EndIf
		EndIf
	EndIf
	GUICtrlSetData($BP_lblVol, _L("VOL") & " " & $BP_iVol)
	GUICtrlSetData($BP_lblBal, $ok ? "BAL " & ($BP_iBal < 0 ? "L" & - $BP_iBal : ($BP_iBal > 0 ? "R" & $BP_iBal : "C")) : _L("BAL n/a"))
	Local $kv = Round($BP_iVol / 100 * $BP_NV), $kb = Round(($BP_iBal + 100) / 200 * ($BP_NB - 1))
	If Not $BP_bPlayerMode Then Return ; the bars are redrawn when the player view opens (BP_Apply is called then)
	For $i = 0 To $BP_NV - 1
		GUICtrlSetBkColor($BP_aV[$i], $i < $kv ? $BP_ACC : $BP_DIM)
	Next
	For $i = 0 To $BP_NB - 1
		GUICtrlSetBkColor($BP_aB[$i], ($i >= _Min(6, $kb) And $i <= _Max(6, $kb)) ? $BP_ACC : $BP_DIM)
	Next
EndFunc   ;==>BP_Apply
; ================= waveform from the file =================
; wav: real amplitude | mp3: loudness estimated from the frames' global_gain (no decoding) | else: default pattern
Func BP_SegX($i) ; bars spread over the full width 24..536
	Return 24 + Round($i * 505 / ($BP_N - 1))
EndFunc   ;==>BP_SegX
Func BP_Def($i)
	Return 8 + Int(Abs(Sin($i * 0.55) * Cos($i * 0.21)) * $BP_WA)
EndFunc   ;==>BP_Def
Func BP_Wave($f)
	Local $v[$BP_N], $ok = False, $e = StringLower(StringRight($f, 4)), $m
	If $e = ".wav" Then $ok = BP_WavEnv($f, $v)
	If $e = ".mp3" Then $ok = BP_Mp3Env($f, $v)
	For $i = 0 To $BP_N - 1
		$m = $ok ? 8 + Int($v[$i] * $BP_WA) : BP_Def($i)
		GUICtrlSetPos($BP_aSeg[$i], BP_SegX($i), $BP_WY - Int($m / 2), 7, $m)
	Next
	If Not $BP_bPlayerMode Then ; moved while hidden -> make sure they stay hidden
		For $i = 0 To $BP_N - 1
			GUICtrlSetState($BP_aSeg[$i], $GUI_HIDE)
		Next
	EndIf
EndFunc   ;==>BP_Wave
Func BP_WavEnv($f, ByRef $v) ; 16-bit PCM only, fills $v with 0..1
	Local $h = FileOpen($f, 16)
	If $h = -1 Then Return False
	Local $t = DllStructCreate("byte[4096]"), $ptr = DllStructGetPtr($t), $p = 12, $ch = 0, $bits = 0, $ds = 0, $dl = 0, $id, $sz, $mx = 0, $sum, $cnt, $b, $pos
	DllStructSetData($t, 1, FileRead($h, 4096))
	If DllStructGetData(DllStructCreate("char[4]", $ptr), 1) <> "RIFF" Then Return FileClose($h) * 0
	While $p < 4000
		$id = DllStructGetData(DllStructCreate("char[4]", $ptr + $p), 1)
		$sz = DllStructGetData(DllStructCreate("dword", $ptr + $p + 4), 1)
		If $id = "fmt " Then
			$ch = DllStructGetData(DllStructCreate("word", $ptr + $p + 10), 1)
			$bits = DllStructGetData(DllStructCreate("word", $ptr + $p + 22), 1)
		ElseIf $id = "data" Then
			$ds = $p + 8
			$dl = _Min($sz, FileGetSize($f) - $ds)
			ExitLoop
		EndIf
		$p += 8 + $sz + BitAND($sz, 1)
	WEnd
	If $ds = 0 Or $bits <> 16 Or $ch < 1 Or $dl < 8192 Then Return FileClose($h) * 0
	Local $fr = $ch * 2, $tb = DllStructCreate("byte[1024]"), $ts = DllStructCreate("short[512]", DllStructGetPtr($tb))
	For $i = 0 To $BP_N - 1
		$sum = 0
		$cnt = 0
		For $j = 0 To 3
			$pos = $ds + Int($dl * ($i + ($j + 0.5) / 4) / $BP_N / $fr) * $fr
			FileSetPos($h, $pos, 0)
			$b = FileRead($h, 1024)
			If @error Then ContinueLoop
			DllStructSetData($tb, 1, $b)
			For $k = 1 To 512 Step 4
				$sum += Abs(DllStructGetData($ts, 1, $k))
				$cnt += 1
			Next
		Next
		$v[$i] = $cnt ? $sum / $cnt : 0
		$mx = _Max($mx, $v[$i])
	Next
	FileClose($h)
	If $mx = 0 Then Return False
	For $i = 0 To $BP_N - 1
		$v[$i] /= $mx
	Next
	Return True
EndFunc   ;==>BP_WavEnv
Func BP_Mp3Env($f, ByRef $v) ; MPEG-1 Layer III, fills $v with 0..1
	Local $h = FileOpen($f, 16)
	If $h = -1 Then Return False
	Local $sz = FileGetSize($f), $lo = 0, $hi, $t = DllStructCreate("byte[4096]"), $b, $g, $sum, $cnt, $tot = 0, $mn = 9999, $mx = 0, $aV = 0
	DllStructSetData($t, 1, FileRead($h, 10))
	If DllStructGetData(DllStructCreate("char[3]", DllStructGetPtr($t)), 1) = "ID3" Then ; skip ID3v2 tag
		$lo = 10 + BitShift(DllStructGetData($t, 1, 7), -21) + BitShift(DllStructGetData($t, 1, 8), -14) + BitShift(DllStructGetData($t, 1, 9), -7) + DllStructGetData($t, 1, 10)
	EndIf
	$hi = $sz - 4096 - 128
	If $hi <= $lo Then Return FileClose($h) * 0
	For $i = 0 To $BP_N - 1
		$sum = 0
		$cnt = 0
		For $j = 0 To 5
			FileSetPos($h, $lo + Int(($hi - $lo) * ($i + ($j + 0.5) / 6) / $BP_N), 0)
			$b = FileRead($h, 4096)
			If @error Then ContinueLoop
			DllStructSetData($t, 1, $b)
			$g = BP_FrameGain($t, BinaryLen($b))
			If $g >= 0 Then
				$sum += $g
				$cnt += 1
			EndIf
		Next
		$v[$i] = $cnt ? $sum / $cnt : -1
		If $cnt Then
			$tot += 1
			$aV += $v[$i]
			$mn = _Min($mn, $v[$i])
			$mx = _Max($mx, $v[$i])
		EndIf
	Next
	FileClose($h)
	If $tot < $BP_N / 2 Then Return False
	$aV /= $tot
	For $i = 0 To $BP_N - 1
		If $v[$i] < 0 Then $v[$i] = $aV
		$v[$i] = ($v[$i] - $mn) / _Max($mx - $mn, 8)
	Next
	Return True
EndFunc   ;==>BP_Mp3Env
Func BP_FrameGain($t, $len) ; first valid MPEG-1 L3 frame in buffer -> mean global_gain (~ loudness in 1.5 dB steps), else -1
	Local $b1, $b2, $b3, $x, $y, $fl, $nc, $bit, $g
	For $p = 0 To $len - 4
		If DllStructGetData($t, 1, $p + 1) <> 255 Then ContinueLoop
		$b1 = DllStructGetData($t, 1, $p + 2)
		If BitAND($b1, 0xFE) <> 0xFA Then ContinueLoop
		$b2 = DllStructGetData($t, 1, $p + 3)
		$x = BitShift($b2, 4)
		$y = BitAND(BitShift($b2, 2), 3)
		If $x = 0 Or $x = 15 Or $y = 3 Then ContinueLoop
		$fl = Int(144000 * $BP_aBR[$x] / $BP_aSR[$y]) + BitAND(BitShift($b2, 1), 1)
		If $p + $fl + 2 > $len Then ExitLoop
		If DllStructGetData($t, 1, $p + $fl + 1) <> 255 Or BitAND(DllStructGetData($t, 1, $p + $fl + 2), 0xF0) <> 0xF0 Then ContinueLoop ; next frame must follow
		$b3 = DllStructGetData($t, 1, $p + 4)
		$nc = (BitShift($b3, 6) = 3) ? 1 : 2
		$bit = 8 * ($p + 4 + (BitAND($b1, 1) ? 0 : 2)) + ($nc = 1 ? 18 : 20)
		$g = 0
		For $k = 0 To 2 * $nc - 1
			$g += BP_GG($t, $bit + $k * 59 + 21)
		Next
		Return $g / (2 * $nc)
	Next
	Return -1
EndFunc   ;==>BP_FrameGain
Func BP_GG($t, $bit) ; 8 bits at bit offset
	Local $o = BitShift($bit, 3), $v = DllStructGetData($t, 1, $o + 1) * 256 + DllStructGetData($t, 1, $o + 2)
	Return BitAND(BitShift($v, 8 - BitAND($bit, 7)), 255)
EndFunc   ;==>BP_GG
; ================= playlist =================
Func BP_Add($f, $l = 0) ; $l = known length in seconds (skips the Explorer lookup)
	$f = BP_Norm($f)
	If StringInStr(FileGetAttrib($f), "D") Then Return BP_AddDir($f)
	If Not StringRegExp($f, "(?i)\.(" & $BP_sExt & ")$") Or Not FileExists($f) Then Return
	Local $bpLn = $l > 0 ? $l : BP_MP3_GetLengthSec($f)
	If Not IsNumber($bpLn) Or $bpLn < 0 Then $bpLn = 0
	If $bpLn <= 0 Then $BP_iFill = 0
	Local $bpK = UBound($BP_aPl)
	If UBound($BP_aLn) <> $bpK Then ReDim $BP_aLn[$bpK]
	ReDim $BP_aPl[$bpK + 1]
	ReDim $BP_aLn[$bpK + 1]
	$BP_aPl[$bpK] = $f
	$BP_aLn[$bpK] = $bpLn
	GUICtrlSetData($BP_lst, BP_Item($bpK))
	BP_PLText()
EndFunc   ;==>BP_Add
Func BP_AddDir($d)
	Local $h, $f
	For $e In StringSplit($BP_sExt, "|", 2)
		$h = FileFindFirstFile($d & "\*." & $e)
		While 1
			$f = FileFindNextFile($h)
			If @error Then ExitLoop
			BP_Add($d & "\" & $f)
		WEnd
		FileClose($h)
	Next
EndFunc   ;==>BP_AddDir
Func BP_LoadDL($bFull = False) ; download folder -> playlist: only files the player did not handle yet ($bFull = everything again). Not after a manually loaded playlist.
	If $g_bPLManual Or Not FileExists($DL_DIR) Then Return
	If $bFull Then $g_sKnown = "|"
	If $hDLProc <> 0 Then $g_bPruneNeed = True
	Local $h, $f, $p, $n, $bHave, $k
	For $e In StringSplit($BP_sExt, "|", 2)
		$h = FileFindFirstFile($DL_DIR & "\*." & $e)
		If $h = -1 Then ContinueLoop
		While 1
			$f = FileFindNextFile($h)
			If @error Then ExitLoop
			If StringLeft($f, 1) = "_" Or StringRegExp($f, "(?i)\.(f\d+|temp)\.[^.]+$") Then ContinueLoop ; temp files / yt-dlp part streams
			$p = BP_Norm($DL_DIR & "\" & $f)
			$k = "|" & StringLower($p) & "|"
			If StringInStr($g_sKnown, $k) Then ContinueLoop
			$bHave = False
			For $n = 0 To UBound($BP_aPl) - 1
				If StringLower($BP_aPl[$n]) = StringLower($p) Then
					$bHave = True
					ExitLoop
				EndIf
			Next
			If Not $bHave Then
				If $hDLProc <> 0 And Not BP_Stable($p) Then ContinueLoop ; still being written
				BP_Add($p)
			EndIf
			$g_sKnown &= StringTrimLeft($k, 1)
		WEnd
		FileClose($h)
	Next
	If $g_bPruneNeed Then BP_PruneDL()
EndFunc   ;==>BP_LoadDL
Func BP_Stable($p) ; while a download runs: a file counts as finished when its size did not change since the last scan
	Local $sz = FileGetSize($p), $k, $bSame
	For $k = 0 To UBound($g_aSeenP) - 1
		If $g_aSeenP[$k] = $p Then
			$bSame = ($g_aSeenS[$k] = $sz)
			$g_aSeenS[$k] = $sz
			Return $bSame
		EndIf
	Next
	$k = UBound($g_aSeenP)
	ReDim $g_aSeenP[$k + 1]
	ReDim $g_aSeenS[$k + 1]
	$g_aSeenP[$k] = $p
	$g_aSeenS[$k] = $sz
	Return False
EndFunc   ;==>BP_Stable
Func BP_PruneDL() ; entries of the download folder whose file is gone (yt-dlp intermediates) leave the list again
	If $hDLProc = 0 Then $g_bPruneNeed = False
	Local $i, $bCh = False
	For $i = UBound($BP_aPl) - 1 To 0 Step -1
		If $i <> $BP_iCur And StringInStr($BP_aPl[$i], $DL_DIR & "\") = 1 And Not FileExists($BP_aPl[$i]) Then
			_ArrayDelete($BP_aPl, $i)
			_ArrayDelete($BP_aLn, $i)
			If $BP_iCur > $i Then $BP_iCur -= 1
			$bCh = True
		EndIf
	Next
	If $bCh Then BP_Refresh()
EndFunc   ;==>BP_PruneDL
Func BP_DropLive() ; live download stopped / restarted: take the live file out of the player
	Local $i, $bCh = False
	For $i = UBound($BP_aPl) - 1 To 0 Step -1
		If StringRight($BP_aPl[$i], 15) = "_watch_live.mp4" Then
			If $i = $BP_iCur Then
				BP_Stop()
				$BP_iCur = -1
			ElseIf $BP_iCur > $i Then
				$BP_iCur -= 1
			EndIf
			_ArrayDelete($BP_aPl, $i)
			_ArrayDelete($BP_aLn, $i)
			$bCh = True
		EndIf
	Next
	If $bCh Then BP_Refresh()
EndFunc   ;==>BP_DropLive
Func BP_DelSel()
	Local $s = GUICtrlSendMsg($BP_lst, $LB_GETCURSEL, 0, 0)
	If $s < 0 Then Return
	_ArrayDelete($BP_aPl, $s)
	_ArrayDelete($BP_aLn, $s)
	If $BP_iCur = $s Then
		BP_Stop()
		$BP_iCur = -1
	ElseIf $BP_iCur > $s Then
		$BP_iCur -= 1
	EndIf
	BP_Refresh()
EndFunc   ;==>BP_DelSel
Func BP_Clear()
	BP_Stop()
	ReDim $BP_aPl[0]
	ReDim $BP_aLn[0]
	$BP_iCur = -1
	BP_Refresh()
EndFunc   ;==>BP_Clear
Func BP_Refresh()
	GUICtrlSetData($BP_lst, "")
	For $i = 0 To UBound($BP_aPl) - 1
		GUICtrlSetData($BP_lst, BP_Item($i))
	Next
	If $BP_iCur >= 0 Then GUICtrlSendMsg($BP_lst, $LB_SETCURSEL, $BP_iCur, 0)
	BP_PLText()
EndFunc   ;==>BP_Refresh
Func BP_Norm($p) ; D:\\folder\file -> D:\folder\file (happens when the exe sits in the root of a drive); a leading \\ (UNC) stays
	Local $pre = (StringLeft($p, 2) = "\\") ? "\\" : ""
	$p = StringTrimLeft($p, StringLen($pre))
	While StringInStr($p, "\\")
		$p = StringReplace($p, "\\", "\")
	WEnd
	Return $pre & $p
EndFunc   ;==>BP_Norm
Func BP_ItemSet($i) ; update one list line in place (keeps scroll position and selection)
	Local $t = BP_Item($i), $w = DllStructCreate("wchar[" & StringLen($t) + 1 & "]")
	DllStructSetData($w, 1, $t)
	Local $top = GUICtrlSendMsg($BP_lst, 0x018E, 0, 0), $sel = GUICtrlSendMsg($BP_lst, $LB_GETCURSEL, 0, 0) ; LB_GETTOPINDEX
	GUICtrlSendMsg($BP_lst, 0x0182, $i, 0) ; LB_DELETESTRING
	GUICtrlSendMsg($BP_lst, 0x0181, $i, DllStructGetPtr($w)) ; LB_INSERTSTRING
	GUICtrlSendMsg($BP_lst, 0x0197, $top, 0) ; LB_SETTOPINDEX
	If $sel >= 0 Then GUICtrlSendMsg($BP_lst, $LB_SETCURSEL, $sel, 0)
EndFunc   ;==>BP_ItemSet
Func BP_FillLen() ; tracks that came in without a length: look it up a few per tick, one pass through the list
	Local $n = UBound($BP_aPl), $c = 0, $l
	While $BP_iFill < $n And $c < 3
		If $BP_aLn[$BP_iFill] <= 0 Then
			$c += 1
			$l = BP_MP3_GetLengthSec($BP_aPl[$BP_iFill])
			If $l <= 0 And $BP_iFillLog < 5 Then
				$BP_iFillLog += 1
				BP_Log("length lookup failed: " & $BP_aPl[$BP_iFill])
			EndIf
			If $l > 0 Then
				$BP_aLn[$BP_iFill] = $l
				BP_ItemSet($BP_iFill)
				If $BP_iFill = $BP_iCur And $BP_iLen <= 0 Then $BP_iLen = $l
			EndIf
		EndIf
		$BP_iFill += 1
	WEnd
EndFunc   ;==>BP_FillLen
Func BP_Item($i)
	Return StringFormat("%02d  %s   [%s]", $i + 1, BP_Name($BP_aPl[$i]), BP_T($BP_aLn[$i]))
EndFunc   ;==>BP_Item
; ---- m3u (extended, UTF-8) ----
Func BP_SaveList($sPath)
	Local $h = FileOpen($sPath, 2 + 8 + 128) ; overwrite, create path, UTF-8
	If $h = -1 Then Return False
	FileWriteLine($h, "#EXTM3U")
	For $i = 0 To UBound($BP_aPl) - 1
		If StringRight($BP_aPl[$i], 15) = "_watch_live.mp4" Then ContinueLoop ; temp file
		FileWriteLine($h, "#EXTINF:" & Int($BP_aLn[$i]) & "," & BP_Name($BP_aPl[$i]))
		FileWriteLine($h, $BP_aPl[$i])
	Next
	FileClose($h)
	Return True
EndFunc   ;==>BP_SaveList
Func BP_LoadList($sPath)
	Local $h = FileOpen($sPath, 256) ; reads UTF-8 with or without BOM
	If $h = -1 Then Return False
	Local $dir = StringLeft($sPath, StringInStr($sPath, "\", 0, -1) - 1), $l = 0, $ln, $c
	While 1
		$ln = FileReadLine($h)
		If @error Then ExitLoop
		$ln = StringStripWS(StringReplace($ln, ChrW(0xFEFF), ""), 3) ; drop BOM remnants + whitespace
		If $ln = "" Then ContinueLoop
		If StringLeft($ln, 8) = "#EXTINF:" Then
			$c = StringInStr($ln, ",")
			$l = $c > 9 ? Int(StringMid($ln, 9, $c - 9)) : 0
			ContinueLoop
		EndIf
		If StringLeft($ln, 1) = "#" Then ContinueLoop
		$ln = StringReplace($ln, "/", "\")
		If Not (StringInStr($ln, ":") Or StringLeft($ln, 2) = "\\") Then $ln = $dir & "\" & $ln ; relative path
		BP_Add($ln, $l)
		$l = 0
	WEnd
	FileClose($h)
	Return True
EndFunc   ;==>BP_LoadList
Func BP_WMClose($hWnd, $iMsg, $wParam, $lParam)
	If $hWnd = $BP_hVid Then
		$BP_fQuit = True
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc   ;==>BP_WMClose
; ================= video window =================
Func BP_IsVid($f)
	Return StringRegExp($f, "(?i)\.(" & $BP_sVid & ")$") = 1
EndFunc   ;==>BP_IsVid
Func BP_VidApply() ; TV button + video window follow: current track is a video? video wanted (remembered)? not in tray?
	Local $on = $BP_fPlay And $BP_fVid
	GUICtrlSetState($BP_bTV, ($on And $BP_bPlayerMode) ? $GUI_SHOW : $GUI_HIDE) ; only in the player view (it showed up in the download view while a video played)
	GUICtrlSetData($BP_bTV, $BP_fVidOn ? _L("VIDEO ON") : _L("VIDEO OFF"))
	GUICtrlSetBkColor($BP_bTV, $BP_fVidOn ? $BP_ACC : 0x3A3A3A)
	GUICtrlSetColor($BP_bTV, $BP_TXT)
	If $on And $BP_fVidOn And Not $BP_fTray And Not $BP_fFF Then ; (ffplay has its own window)
		BP_VidStyle()
		BP_Dock()
		GUISetState(@SW_SHOWNOACTIVATE, $BP_hVid)
		WinSetOnTop($BP_hVid, "", ($BP_fFull And Not $BP_fWmp) ? 1 : 0)
		If $BP_fWmp And Not $BP_fFull Then ; WMP window mode: WMP leaves its fullscreen (in BP_VideoSize) - not the user leaving it
			$BP_fWFS = False
			BP_WmpKeys(False)
		EndIf
		$BP_fVidShown = True
		BP_VideoSize()
		If $BP_fFull And Not $BP_fWmp Then WinActivate($BP_hMain) ; the keyboard stays with the player (shortcuts keep working in fullscreen)
	Else
		If IsObj($BP_oWMP) Then $BP_oWMP.fullScreen = False ; leave WMP's own fullscreen
		BP_WmpKeys(False)
		$BP_fWFS = False ; WMP is out of fullscreen -> the next fullscreen entry must register the hotkeys again (else the keys stay dead and only Esc works)
		GUISetState(@SW_HIDE, $BP_hOsd)
		$BP_tOsd = 0
		GUISetState(@SW_HIDE, $BP_hVid)
		$BP_fVidShown = False
		BP_Cursor(True)
		BP_KeepAwake(False)
	EndIf
	GUISwitch($BP_hMain)
EndFunc   ;==>BP_VidApply
Func BP_Dock() ; MCI fullscreen: the video monitor | MCI window: placed by _VideoSize | WMP: invisible host window on the video monitor (its fullscreen follows it)
	Local $r = BP_VidMonitor()
	If $BP_fWmp Then
		If $BP_fFull Then WinMove($BP_hVid, "", $r[0] + 20, $r[1] + 20, $BP_iWw, $BP_iWh)
		Return
	EndIf
	Local $p = WinGetPos($BP_hMain)
	If $BP_fFull And IsArray($p) Then
		WinMove($BP_hVid, "", $r[0], $r[1], $r[2], $r[3])
		$BP_sPos = $p[0] & "," & $p[1]
	EndIf
EndFunc   ;==>BP_Dock
Func BP_VidStyle() ; 0 = fullscreen (borderless) | 1 = window (title bar) | 2 = WMP host (invisible, click-through, sits on the video monitor)
	Local $m = $BP_fFull ? ($BP_fWmp ? 2 : 0) : 1
	If $m = $BP_iSty Then Return
	$BP_iSty = $m
	If $m = 1 Then
		GUISetStyle(BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU, $WS_CLIPCHILDREN), $WS_EX_NOACTIVATE, $BP_hVid)
	ElseIf $m = 2 Then
		GUISetStyle(BitOR($WS_POPUP, $WS_CLIPCHILDREN), BitOR($WS_EX_NOACTIVATE, $WS_EX_TRANSPARENT, $WS_EX_LAYERED), $BP_hVid)
	Else
		GUISetStyle(BitOR($WS_POPUP, $WS_CLIPCHILDREN), $WS_EX_NOACTIVATE, $BP_hVid)
	EndIf
	WinSetTrans($BP_hVid, "", $m = 2 ? 0 : 255)
	DllCall("user32.dll", "bool", "SetWindowPos", "hwnd", $BP_hVid, "hwnd", 0, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 0x37) ; frame changed
EndFunc   ;==>BP_VidStyle
Func BP_ToggleVid() ; TV button / V key
	If Not ($BP_fPlay And $BP_fVid) Then Return
	$BP_fVidOn = Not $BP_fVidOn
	BP_FFRestart() ; ffplay can't hide its picture while running: restart at the same second, with or without picture
	BP_VidApply()
EndFunc   ;==>BP_ToggleVid
Func BP_FFRestart() ; restart a running ffplay video at the same second (new picture / fullscreen / volume / balance settings)
	If Not $BP_fFF Or $BP_fPause Then Return
	Local $s = BP_Pos()
	BP_FFStart($BP_aPl[$BP_iCur], $s)
	$BP_tCmd = TimerInit()
	$BP_iOff = $s
	$BP_tRun = TimerInit()
EndFunc   ;==>BP_FFRestart
Func BP_VidKey($k) ; f = fullscreen <-> window (video off -> on, fullscreen) - same in every play mode; V (video on/off) = BP_ToggleVid
	If Not ($BP_fPlay And $BP_fVid) Then Return
	If $k <> "f" Then Return
	If $BP_fFF Then ; ffplay: no switch from outside -> restart at the same second with / without -fs
		If $BP_fVidOn Then
			$BP_fFull = Not $BP_fFull
		Else
			$BP_fVidOn = True
			$BP_fFull = True
		EndIf
		BP_FFRestart()
		BP_VidApply()
		Return
	EndIf
	If $BP_fVidShown And Not $BP_fFull Then BP_MonRemember() ; window was maybe dragged to another monitor -> fullscreen goes there
	If Not $BP_fVidOn Then
		$BP_fVidOn = True
		$BP_fFull = True
	Else
		$BP_fFull = Not $BP_fFull
	EndIf
	$BP_sWin = ""
	$BP_tChg = TimerInit()
	BP_VidApply()
EndFunc   ;==>BP_VidKey
Func BP_VidPoll() ; called every ~30 ms while the video window is visible
	Local $q, $r, $dn = False, $mp, $now
	If $BP_tOsd And TimerDiff($BP_tOsd) > $BP_iOsdMs Then ; OSD timeout
		$BP_tOsd = 0
		GUISetState(@SW_HIDE, $BP_hOsd)
	EndIf
	BP_KeepAwake(Not $BP_fPause) ; no screensaver / display sleep while a video is shown (not while paused)
	If $BP_fWmp Then
		If Not $BP_fFull And Not $BP_fTray And WinActive($BP_hVid) Then WinActivate($BP_hMain) ; window mode: a click in the picture gives the focus to WMP -> hand the keyboard back to the player (its keys only work there)
		If $BP_iVSz >= 1 Then
			$now = ($BP_oWMP.fullScreen <> 0)
			If $now Then
				If Not $BP_fWFS Then ; WMP just went fullscreen: it owns the keyboard now -> our keys as global hotkeys, title on screen
					$BP_fWFS = True
					BP_WmpKeys(True)
					BP_Osd($BP_sNow, 4000)
					If Not $BP_fFull Then ; the user entered WMP's fullscreen itself (double click in the picture)
						$BP_fFull = True
						$BP_sWin = ""
					EndIf
				EndIf
			ElseIf $BP_fWFS And TimerDiff($BP_tStart) > 1500 Then ; WMP left its fullscreen
				$BP_fWFS = False
				$mp = $BP_oWMP.playState
				If $mp = 3 Or $mp = 2 Then ; still playing / paused = the user left it (Esc / double-click) -> window mode
					BP_Log("WMP fullscreen left by the user -> window")
					$BP_fFull = False
					$BP_sWin = ""
					$BP_tChg = TimerInit()
					BP_VidApply()
				Else ; the video ended and WMP leaves fullscreen by itself -> keep "video wanted", the next video opens the window again
					BP_Log("WMP fullscreen left (video ended, state " & $mp & ")")
				EndIf
			EndIf
		EndIf
		Return
	EndIf
	If $BP_fFull Then
		$q = WinGetPos($BP_hMain)
		If IsArray($q) Then
			If $q[0] & "," & $q[1] <> $BP_sPos Then ; player moved (maybe to another monitor) -> fullscreen follows
				$BP_iMon = 0
				BP_Dock()
				BP_VideoSize()
			EndIf
		EndIf
		$mp = MouseGetPos() ; mouse cursor: hidden after 3 s without movement, back on movement
		If $mp[0] <> $BP_iMx Or $mp[1] <> $BP_iMy Then
			$BP_iMx = $mp[0]
			$BP_iMy = $mp[1]
			$BP_tMouse = TimerInit()
			BP_Cursor(True)
		ElseIf TimerDiff($BP_tMouse) > 3000 Then
			If BP_OverVideo(False) Then BP_Cursor(False)
		EndIf
	Else
		BP_Cursor(True)
	EndIf
	$r = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 1)
	If IsArray($r) Then $dn = BitAND($r[0], 0x8000) <> 0
	If $dn And Not $BP_bDown Then ; new left click on the video
		If BP_OverVideo(Not $BP_fFull) Then
			If Not WinActive($BP_hMain) Then WinActivate($BP_hMain) ; keep the keyboard on the player
			If $BP_fClick And TimerDiff($BP_tChg) > 500 Then BP_VidKey("f") ; single click: fullscreen <-> window
		EndIf
	EndIf
	$BP_bDown = $dn
EndFunc   ;==>BP_VidPoll
Func BP_Monitors() ; [n][4] = x, y, w, h of every monitor
	Local $a = _WinAPI_EnumDisplayMonitors()
	If Not IsArray($a) Then
		Local $d[1][4] = [[0, 0, @DesktopWidth, @DesktopHeight]]
		Return $d
	EndIf
	If $a[0][0] < 1 Then
		Local $e[1][4] = [[0, 0, @DesktopWidth, @DesktopHeight]]
		Return $e
	EndIf
	Local $r[$a[0][0]][4], $t
	For $i = 1 To $a[0][0]
		$t = $a[$i][1]
		$r[$i - 1][0] = DllStructGetData($t, "Left")
		$r[$i - 1][1] = DllStructGetData($t, "Top")
		$r[$i - 1][2] = DllStructGetData($t, "Right") - $r[$i - 1][0]
		$r[$i - 1][3] = DllStructGetData($t, "Bottom") - $r[$i - 1][1]
	Next
	Return $r
EndFunc   ;==>BP_Monitors
Func BP_VidMonitor() ; [x, y, w, h] of the monitor the video goes to: the one chosen with D, else the player's
	If $BP_iMon > 0 Then
		Local $m = BP_Monitors()
		If $BP_iMon <= UBound($m) Then
			Local $r[4] = [$m[$BP_iMon - 1][0], $m[$BP_iMon - 1][1], $m[$BP_iMon - 1][2], $m[$BP_iMon - 1][3]]
			Return $r
		EndIf
	EndIf
	Return BP_MonitorRect($BP_hMain)
EndFunc   ;==>BP_VidMonitor
Func BP_MonRemember() ; the video window sits on another monitor than the player: that monitor is the video monitor from now on
	Local $c = BP_MonitorRect($BP_hVid), $mo = BP_Monitors()
	For $i = 0 To UBound($mo) - 1
		If $mo[$i][0] = $c[0] And $mo[$i][1] = $c[1] Then
			$BP_iMon = $i + 1
			ExitLoop
		EndIf
	Next
EndFunc   ;==>BP_MonRemember
Func BP_NextMonitor() ; D: send the video to the next monitor (back to "the player's monitor" as soon as the player is moved)
	If Not ($BP_fPlay And $BP_fVid And $BP_fVidOn) Then Return
	Local $m = BP_Monitors(), $c = BP_VidMonitor(), $idx = 0
	If UBound($m) < 2 Then
		BP_Note("only one monitor")
		Return
	EndIf
	For $i = 0 To UBound($m) - 1
		If $m[$i][0] = $c[0] And $m[$i][1] = $c[1] Then $idx = $i
	Next
	$BP_iMon = Mod($idx + 1, UBound($m)) + 1
	If $BP_fWmp Then ; WMP picks the monitor when it enters fullscreen: leave it, move the host window, enter again
		$BP_fWFS = False
		$BP_oWMP.fullScreen = False
		Sleep(350)
	EndIf
	$BP_sWin = ""
	BP_VidApply()
	BP_Note(_L("video on monitor ") & $BP_iMon)
EndFunc   ;==>BP_NextMonitor
Func BP_Zoom($d) ; + / - / 0: zoom the video (odd resolutions, baked-in black bars); MCI videos only
	If Not ($BP_fPlay And $BP_fVid) Then Return
	If $BP_fWmp Then
		BP_Note("zoom is not available for WMP videos")
		Return
	EndIf
	If $d = 0 Then
		$BP_iZoom = 100
	Else
		$BP_iZoom = _Min(_Max($BP_iZoom + $d, 50), 300)
	EndIf
	BP_VideoSize()
	BP_Note(_L("zoom ") & $BP_iZoom & "%")
EndFunc   ;==>BP_Zoom
Func BP_AudioTrack() ; A: next audio track (WMP: its audio languages; the MCI driver has no track selection)
	If Not ($BP_fPlay And $BP_fVid) Then Return
	If Not $BP_fWmp Then
		BP_Note("audio track selection is not available in MCI mode")
		Return
	EndIf
	Local $c = $BP_oWMP.controls, $cnt, $i, $nm = ""
	If Not IsObj($c) Then Return
	$cnt = Number($c.audioLanguageCount)
	If $cnt < 2 Then
		BP_Note("audio: only one track")
		Return
	EndIf
	$i = Number($c.currentAudioLanguageIndex) + 1
	If $i >= $cnt Then $i = 0
	$c.currentAudioLanguageIndex = $i
	$nm = $c.getLanguageName($c.getAudioLanguageID($i))
	BP_Note(_L("audio ") & ($i + 1) & "/" & $cnt & ($nm <> "" ? ": " & $nm : ""))
EndFunc   ;==>BP_AudioTrack
Func BP_Note($t) ; short message in the player header and (while a video is shown) on the video
	$t = _L($t)
	GUICtrlSetData($BP_lblNow, $t)
	$BP_tNote = TimerInit()
	BP_Osd($t, 2500)
EndFunc   ;==>BP_Note
Func BP_Osd($t, $ms = 3000) ; text strip above the video: top left of the player's monitor (window mode: of the video window)
	If Not $BP_fVidShown Or $BP_fTray Then Return
	Local $r = BP_VidMonitor(), $x = $r[0] + 24, $y = $r[1] + 24, $wd = _Max(400, Int($r[2] * 0.5)), $p
	If Not $BP_fFull And Not $BP_fWmp Then
		$p = WinGetPos($BP_hVid)
		If IsArray($p) Then
			$x = $p[0] + 16
			$y = $p[1] + 16
			$wd = _Max(300, $p[2] - 32)
		EndIf
	EndIf
	GUICtrlSetData($BP_lblOsd, $t)
	GUICtrlSetPos($BP_lblOsd, 12, 6, $wd - 24, 28)
	WinMove($BP_hOsd, "", $x, $y, $wd, 40)
	GUISetState(@SW_SHOWNOACTIVATE, $BP_hOsd)
	WinSetOnTop($BP_hOsd, "", 1)
	$BP_tOsd = TimerInit()
	$BP_iOsdMs = $ms
	GUISwitch($BP_hMain)
EndFunc   ;==>BP_Osd
Func BP_WmpKeys($on) ; while WMP is fullscreen it owns the keyboard: register our keys as global hotkeys (only then)
	If $on = $BP_fWK Then Return
	$BP_fWK = $on
	Local $k = StringSplit("{SPACE}|{LEFT}|{RIGHT}|{UP}|{DOWN}|^{UP}|^{DOWN}|n|p|s|m|f|v|a|d", "|", 2)
	Local $f = StringSplit("BP_PlayPause|BP_HkBack|BP_HkFwd|BP_HkVU|BP_HkVD|BP_HkVU|BP_HkVD|BP_HkNext|BP_Prev|BP_Stop|BP_Mute|BP_HkF|BP_HkV|BP_AudioTrack|BP_NextMonitor", "|", 2)
	For $i = 0 To UBound($k) - 1
		If $on Then
			HotKeySet($k[$i], $f[$i])
		Else
			HotKeySet($k[$i])
		EndIf
	Next
EndFunc   ;==>BP_WmpKeys
Func BP_HkBack()
	BP_Skip(-5)
EndFunc   ;==>BP_HkBack
Func BP_HkFwd()
	BP_Skip(5)
EndFunc   ;==>BP_HkFwd
Func BP_HkVU()
	BP_Vol(5)
EndFunc   ;==>BP_HkVU
Func BP_HkVD()
	BP_Vol(-5)
EndFunc   ;==>BP_HkVD
Func BP_HkF()
	BP_VidKey("f")
EndFunc   ;==>BP_HkF
Func BP_HkV()
	BP_ToggleVid()
EndFunc   ;==>BP_HkV
Func BP_Cursor($show) ; show / hide the mouse cursor (ShowCursor keeps a counter)
	If $show = $BP_fCurOn Then Return
	$BP_fCurOn = $show
	Local $r, $v, $i = 0
	Do
		$r = DllCall("user32.dll", "int", "ShowCursor", "bool", $show)
		$v = IsArray($r) ? $r[0] : ($show ? 0 : -1)
		$i += 1
	Until ($show ? $v >= 0 : $v < 0) Or $i > 20
EndFunc   ;==>BP_Cursor
Func BP_KeepAwake($on) ; no screensaver / display sleep while on (SetThreadExecutionState instead of faking input)
	If $on = $BP_fAwake Then Return
	$BP_fAwake = $on
	DllCall("kernel32.dll", "dword", "SetThreadExecutionState", "dword", $on ? 0x80000003 : 0x80000000) ; ES_CONTINUOUS (+ DISPLAY + SYSTEM required)
EndFunc   ;==>BP_KeepAwake
Func BP_PLText()
	GUICtrlSetData($BP_bPL, "PLAYLIST   (" & UBound($BP_aPl) & ")")
EndFunc   ;==>BP_PLText
Func BP_OverVideo($bClient = False) ; is the mouse over the (visible, not covered) video window? $bClient: only over the picture, not the title bar
	Local $m = MouseGetPos(), $t = DllStructCreate($tagPOINT)
	DllStructSetData($t, "X", $m[0])
	DllStructSetData($t, "Y", $m[1])
	Local $h = _WinAPI_WindowFromPoint($t)
	If Not $h Then Return False
	If $bClient And $h = $BP_hVid Then Return False
	Return _WinAPI_GetAncestor($h, 2) = $BP_hVid ; GA_ROOT
EndFunc   ;==>BP_OverVideo
Func BP_MonitorRect($hWnd) ; [x, y, w, h] of the monitor the window is on
	Local $a[4] = [0, 0, @DesktopWidth, @DesktopHeight]
	Local $r = DllCall("user32.dll", "handle", "MonitorFromWindow", "hwnd", $hWnd, "dword", 2) ; nearest monitor
	If Not IsArray($r) Then Return $a
	Local $t = DllStructCreate("dword;long;long;long;long;long;long;long;long;dword")
	DllStructSetData($t, 1, DllStructGetSize($t))
	$r = DllCall("user32.dll", "bool", "GetMonitorInfoW", "handle", $r[0], "struct*", $t)
	If Not IsArray($r) Then Return $a
	If Not $r[0] Then Return $a
	$a[0] = DllStructGetData($t, 2)
	$a[1] = DllStructGetData($t, 3)
	$a[2] = DllStructGetData($t, 4) - $a[0]
	$a[3] = DllStructGetData($t, 5) - $a[1]
	Return $a
EndFunc   ;==>BP_MonitorRect
Func BP_WmpFit() ; WMP window mode: client area = video size (scaled down if it does not fit the monitor), the WMP control fills it
	Local $z = WinGetClientSize($BP_hVid)
	If Not IsArray($z) Then Return
	If $z[0] < 2 Or $z[1] < 2 Then Return
	Local $oM = $BP_oWMP.currentMedia, $sw = 0, $sh = 0
	If IsObj($oM) Then
		$sw = Number($oM.imageSourceWidth)
		$sh = Number($oM.imageSourceHeight)
	EndIf
	Local $mr = BP_VidMonitor(), $cw = ($sw > 0) ? $sw : 640, $ch = ($sh > 0) ? $sh : 360
	Local $k = _Min(1, _Min($mr[2] * 0.9 / $cw, $mr[3] * 0.9 / $ch))
	$cw = Int($cw * $k)
	$ch = Int($ch * $k)
	Local $bNewSz = ($BP_sWin <> $cw & "x" & $ch)
	If $bNewSz Then ; new video / mode: resize + center once (afterwards the user may move the window)
		$BP_sWin = $cw & "x" & $ch
		Local $ps = WinGetPos($BP_hVid)
		If IsArray($ps) Then
			Local $ex = $ps[2] - $z[0], $ey = $ps[3] - $z[1] ; title bar + borders
			WinMove($BP_hVid, "", $mr[0] + Int(($mr[2] - $cw - $ex) / 2), $mr[1] + Int(($mr[3] - $ch - $ey) / 2), $cw + $ex, $ch + $ey)
		EndIf
	EndIf
	$z = WinGetClientSize($BP_hVid) ; the control fills what the window really has now (not what we calculated)
	If IsArray($z) Then
		If $z[0] > 1 And $z[1] > 1 Then
			$cw = $z[0]
			$ch = $z[1]
		EndIf
	EndIf
	GUICtrlSetPos($BP_idWMP, 0, 0, $cw, $ch)
	If $bNewSz Then ; WMP keeps the picture layout of the first video of the session -> force it to lay the picture out again for this window
		GUICtrlSetPos($BP_idWMP, 0, 0, $cw - 1, $ch - 1)
		GUICtrlSetPos($BP_idWMP, 0, 0, $cw, $ch)
		$BP_oWMP.stretchToFit = False
		$BP_oWMP.stretchToFit = True
		$BP_oWMP.uiMode = "none"
	EndIf
EndFunc   ;==>BP_WmpFit
Func BP_VideoSize() ; MCI: fullscreen = picture letterboxed into the monitor | window = client area gets the video's size. WMP: fullscreen is its own
	If Not ($BP_fPlay And $BP_fVid) Then Return
	If $BP_fWmp Then
		$BP_oWMP.stretchToFit = True
		If $BP_fVidOn And $BP_iVSz >= 1 Then
			If $BP_fFull Then
				If Not $BP_oWMP.fullScreen Then $BP_oWMP.fullScreen = True
			Else ; window mode: out of WMP's fullscreen, window = video size
				If $BP_oWMP.fullScreen Then $BP_oWMP.fullScreen = False
				BP_WmpFit()
			EndIf
		EndIf
		Return
	EndIf
	Local $z = WinGetClientSize($BP_hVid)
	If Not IsArray($z) Then Return
	If $z[0] < 2 Or $z[1] < 2 Then Return
	Local $a = StringSplit(BP_Mci("where bp source"), " ", 2), $x = 0, $y = 0, $w = $z[0], $h = $z[1], $k, $sw = 0, $sh = 0
	If UBound($a) >= 4 Then
		$sw = Number($a[2])
		$sh = Number($a[3])
	EndIf
	If Not $BP_fFull Then ; window: client area = video size (scaled down if it does not fit the monitor)
		Local $mr = BP_VidMonitor(), $cw = ($sw > 0) ? $sw : 640, $ch = ($sh > 0) ? $sh : 360
		$k = _Min(1, _Min($mr[2] * 0.9 / $cw, $mr[3] * 0.9 / $ch))
		$cw = Int($cw * $k)
		$ch = Int($ch * $k)
		If $BP_sWin <> $cw & "x" & $ch Then ; new video / mode: resize + center once (afterwards the user may move the window)
			$BP_sWin = $cw & "x" & $ch
			Local $ps = WinGetPos($BP_hVid)
			If IsArray($ps) Then
				Local $ex = $ps[2] - $z[0], $ey = $ps[3] - $z[1] ; title bar + borders
				WinMove($BP_hVid, "", $mr[0] + Int(($mr[2] - $cw - $ex) / 2), $mr[1] + Int(($mr[3] - $ch - $ey) / 2), $cw + $ex, $ch + $ey)
			EndIf
		EndIf
		$w = Int($cw * $BP_iZoom / 100) ; zoom: bigger than the window = cropped (the window clips), smaller = black border
		$h = Int($ch * $BP_iZoom / 100)
		BP_Mci("put bp window at " & Int(($cw - $w) / 2) & " " & Int(($ch - $h) / 2) & " " & $w & " " & $h)
		Return
	EndIf
	If $sw > 0 And $sh > 0 Then ; fullscreen: keep the aspect ratio, black bars
		$k = _Min($z[0] / $sw, $z[1] / $sh)
		$w = Int($sw * $k)
		$h = Int($sh * $k)
	EndIf
	$w = Int($w * $BP_iZoom / 100) ; zoom (+ / -)
	$h = Int($h * $BP_iZoom / 100)
	$x = Int(($z[0] - $w) / 2)
	$y = Int(($z[1] - $h) / 2)
	BP_Mci("put bp window at " & $x & " " & $y & " " & $w & " " & $h)
EndFunc   ;==>BP_VideoSize
; ================= helpers =================
Func BP_SoundPlayFixMP3($sFile, $sOut = "")
	If $sOut = "" Then $sOut = @TempDir & "\SoundPlay_clean.mp3"
	If Not FileExists($sFile) Then Return ""
	Local $hIn = FileOpen($sFile, 16)
	If $hIn = -1 Then Return ""
	Local $iSize = FileGetSize($sFile), $iStart = 0, $iAudioStart, $bHeader = FileRead($hIn, 10), $b1, $b2, $b3, $b4
	If BinaryLen($bHeader) = 10 And BinaryToString(BinaryMid($bHeader, 1, 3)) = "ID3" Then ; skip the ID3v2 block (syncsafe size)
		$b1 = Dec(Hex(BinaryMid($bHeader, 7, 1)))
		$b2 = Dec(Hex(BinaryMid($bHeader, 8, 1)))
		$b3 = Dec(Hex(BinaryMid($bHeader, 9, 1)))
		$b4 = Dec(Hex(BinaryMid($bHeader, 10, 1)))
		If Not (BitAND($b1, 0x80) Or BitAND($b2, 0x80) Or BitAND($b3, 0x80) Or BitAND($b4, 0x80)) Then
			$iStart = 10 + $b1 * 2097152 + $b2 * 16384 + $b3 * 128 + $b4
			If BitAND(Dec(Hex(BinaryMid($bHeader, 6, 1))), 0x10) Then $iStart += 10 ; ID3v2 footer
			If $iStart >= $iSize Then $iStart = 0
		EndIf
	EndIf
	$iAudioStart = BP_FindStream($hIn, $iStart, $iSize) ; first real MPEG stream (3 matching frames in a row)
	If $iAudioStart < 0 Then $iAudioStart = $iStart ; none found: at least drop the ID3v2 block
	If $iAudioStart <= 0 Then ; file already starts with audio
		FileClose($hIn)
		Return $sFile
	EndIf
	FileDelete($sOut)
	Local $hOut = FileOpen($sOut, 18)
	If $hOut = -1 Then
		FileClose($hIn)
		Return ""
	EndIf
	FileSetPos($hIn, $iAudioStart, 0)
	Local $iRemaining = $iSize - $iAudioStart, $iChunk = 1024 * 1024, $iRead, $bData
	While $iRemaining > 0
		$iRead = ($iRemaining < $iChunk) ? $iRemaining : $iChunk
		$bData = FileRead($hIn, $iRead)
		If @error Or BinaryLen($bData) = 0 Then
			FileClose($hIn)
			FileClose($hOut)
			FileDelete($sOut)
			Return ""
		EndIf
		FileWrite($hOut, $bData)
		$iRemaining -= BinaryLen($bData)
	WEnd
	FileClose($hIn)
	FileClose($hOut)
	If Not FileExists($sOut) Or FileGetSize($sOut) = 0 Then
		FileDelete($sOut)
		Return ""
	EndIf
	Return $sOut
EndFunc   ;==>BP_SoundPlayFixMP3
Func BP_FindStream($hIn, $iFrom, $iSize) ; file offset of the first valid MPEG stream at/after $iFrom, or -1 (scans max. 1 MB)
	Local $iCh = 65536, $iLa = 8192, $t = DllStructCreate("byte[" & ($iCh + $iLa) & "]")
	Local $iPos = $iFrom, $iLim = ($iSize < $iFrom + 1048576) ? $iSize : $iFrom + 1048576, $b, $BP_iLen, $iEnd, $p
	While $iPos < $iLim
		FileSetPos($hIn, $iPos, 0)
		$b = FileRead($hIn, $iCh + $iLa)
		If @error Then ExitLoop
		$BP_iLen = BinaryLen($b)
		DllStructSetData($t, 1, $b)
		$iEnd = ($BP_iLen < $iCh + $iLa) ? $BP_iLen - 4 : $iCh - 1 ; last chunk: scan to the end
		For $p = 0 To $iEnd
			If DllStructGetData($t, 1, $p + 1) <> 255 Then ContinueLoop
			If BP_IsStream($t, $p, $BP_iLen) Then Return $iPos + $p
		Next
		If $BP_iLen < $iCh + $iLa Then ExitLoop
		$iPos += $iCh
	WEnd
	Return -1
EndFunc   ;==>BP_FindStream
Func BP_IsStream($t, $p, $BP_iLen) ; True if 3 consecutive frames with the same version/layer/samplerate start at $p
	Local $q = $p, $fl, $sig, $s1 = 0
	For $k = 1 To 3
		If $q + 4 > $BP_iLen Then Return False
		$fl = BP_FrameLen($t, $q, $sig)
		If $fl < 24 Then Return False
		If $k = 1 Then $s1 = $sig
		If $sig <> $s1 Then Return False
		$q += $fl
	Next
	Return True
EndFunc   ;==>BP_IsStream
Func BP_FrameLen($t, $p, ByRef $sig) ; MPEG audio frame header at buffer offset $p -> frame length in bytes (0 = no valid header), $sig = version/layer/samplerate
	$sig = 0
	If DllStructGetData($t, 1, $p + 1) <> 255 Then Return 0
	Local $b1 = DllStructGetData($t, 1, $p + 2), $b2 = DllStructGetData($t, 1, $p + 3)
	If BitAND($b1, 0xE0) <> 0xE0 Then Return 0
	Local $v = BitAND(BitShift($b1, 3), 3), $l = BitAND(BitShift($b1, 1), 3) ; v: 3 = MPEG1, 2 = MPEG2, 0 = MPEG2.5 | l: 3 = L1, 2 = L2, 1 = L3
	Local $bi = BitShift($b2, 4), $si = BitAND(BitShift($b2, 2), 3), $pad = BitAND(BitShift($b2, 1), 1)
	If $v = 1 Or $l = 0 Or $bi = 0 Or $bi = 15 Or $si = 3 Then Return 0
	Local $m1 = ($v = 3), $tb, $ts, $a, $br, $sr, $fl
	Local $sBT = "0|32|64|96|128|160|192|224|256|288|320|352|384|416|448;0|32|48|56|64|80|96|112|128|160|192|224|256|320|384;0|32|40|48|56|64|80|96|112|128|160|192|224|256|320;0|32|48|56|64|80|96|112|128|144|160|176|192|224|256;0|8|16|24|32|40|48|56|64|80|96|112|128|144|160"
	Local $sST = "44100|48000|32000;22050|24000|16000;11025|12000|8000"
	If $m1 Then
		$tb = 3 - $l
	Else
		$tb = ($l = 3) ? 3 : 4
	EndIf
	$a = StringSplit($sBT, ";", 2)
	$a = StringSplit($a[$tb], "|", 2)
	$br = $a[$bi] * 1000
	$ts = $m1 ? 0 : ($v = 2 ? 1 : 2) ; samplerate table: MPEG1 / MPEG2 / MPEG2.5
	$a = StringSplit($sST, ";", 2)
	$a = StringSplit($a[$ts], "|", 2)
	$sr = $a[$si]
	If $l = 3 Then
		$fl = (Int(12 * $br / $sr) + $pad) * 4
	ElseIf $l = 1 And Not $m1 Then
		$fl = Int(72 * $br / $sr) + $pad
	Else
		$fl = Int(144 * $br / $sr) + $pad
	EndIf
	$sig = $v * 100 + $l * 10 + $si
	Return $fl
EndFunc   ;==>BP_FrameLen
; ================= file info via Explorer columns =================
; "Artist - Title" from the tags, else the file name
Func BP_MpegHdr($t, $p) ; [frame length, bitrate (bit/s), samplerate, samples per frame, channels, signature] - all 0 if there is no valid header
	Local $r[6] = [0, 0, 0, 0, 0, 0]
	If DllStructGetData($t, 1, $p + 1) <> 255 Then Return $r
	Local $b1 = DllStructGetData($t, 1, $p + 2), $b2 = DllStructGetData($t, 1, $p + 3), $b3 = DllStructGetData($t, 1, $p + 4)
	If BitAND($b1, 0xE0) <> 0xE0 Then Return $r
	Local $v = BitAND(BitShift($b1, 3), 3), $l = BitAND(BitShift($b1, 1), 3) ; v: 3 = MPEG1, 2 = MPEG2, 0 = MPEG2.5 | l: 3 = L1, 2 = L2, 1 = L3
	Local $bi = BitShift($b2, 4), $si = BitAND(BitShift($b2, 2), 3), $pad = BitAND(BitShift($b2, 1), 1)
	If $v = 1 Or $l = 0 Or $bi = 0 Or $bi = 15 Or $si = 3 Then Return $r
	Local $m1 = ($v = 3), $tb, $ts, $a, $br, $sr, $fl, $spf
	Local $sBT = "0|32|64|96|128|160|192|224|256|288|320|352|384|416|448;0|32|48|56|64|80|96|112|128|160|192|224|256|320|384;0|32|40|48|56|64|80|96|112|128|160|192|224|256|320;0|32|48|56|64|80|96|112|128|144|160|176|192|224|256;0|8|16|24|32|40|48|56|64|80|96|112|128|144|160"
	Local $sST = "44100|48000|32000;22050|24000|16000;11025|12000|8000"
	If $m1 Then
		$tb = 3 - $l
	Else
		$tb = ($l = 3) ? 3 : 4
	EndIf
	$a = StringSplit($sBT, ";", 2)
	$a = StringSplit($a[$tb], "|", 2)
	$br = $a[$bi] * 1000
	$ts = $m1 ? 0 : ($v = 2 ? 1 : 2) ; samplerate table: MPEG1 / MPEG2 / MPEG2.5
	$a = StringSplit($sST, ";", 2)
	$a = StringSplit($a[$ts], "|", 2)
	$sr = $a[$si]
	If $l = 3 Then
		$fl = (Int(12 * $br / $sr) + $pad) * 4
		$spf = 384
	ElseIf $l = 1 And Not $m1 Then
		$fl = Int(72 * $br / $sr) + $pad
		$spf = 576
	Else
		$fl = Int(144 * $br / $sr) + $pad
		$spf = 1152
	EndIf
	$r[0] = $fl
	$r[1] = $br
	$r[2] = $sr
	$r[3] = $spf
	$r[4] = (BitShift($b3, 6) = 3) ? 1 : 2
	$r[5] = $v * 100 + $l * 10 + $si
	Return $r
EndFunc   ;==>BP_MpegHdr
Func BP_BE32($t, $o) ; big-endian dword at byte offset $o of a byte[] struct
	Return DllStructGetData($t, 1, $o + 1) * 16777216 + DllStructGetData($t, 1, $o + 2) * 65536 + DllStructGetData($t, 1, $o + 3) * 256 + DllStructGetData($t, 1, $o + 4)
EndFunc   ;==>BP_BE32
Func BP_LenNative($f) ; length without the Shell: mp3 (Xing/Info frame count, else CBR estimate), wav, mp4/m4v/mov (mvhd), avi (avih); audio else via MCI
	Local $e = StringLower(StringRegExpReplace($f, "^.*\.", "")), $l = 0
	Switch $e
		Case "mp3"
			$l = BP_LenMp3($f)
		Case "wav"
			$l = BP_LenWav($f)
		Case "mp4", "m4v", "mov"
			$l = BP_LenMp4($f)
		Case "avi"
			$l = BP_LenAvi($f)
	EndSwitch
	If $l <= 0 And ($e = "mp3" Or $e = "wav" Or $e = "wma") Then $l = BP_LenMci($f)
	Return $l
EndFunc   ;==>BP_LenNative
Func BP_LenMp3($f)
	Local $h = FileOpen($f, 16)
	If $h = -1 Then Return 0
	Local $sz = FileGetSize($f), $t = DllStructCreate("byte[4096]"), $lo = 0, $pos, $a, $v, $xo, $id, $fr
	DllStructSetData($t, 1, FileRead($h, 10))
	If DllStructGetData(DllStructCreate("char[3]", DllStructGetPtr($t)), 1) = "ID3" Then ; skip the ID3v2 block
		$lo = 10 + BitShift(DllStructGetData($t, 1, 7), -21) + BitShift(DllStructGetData($t, 1, 8), -14) + BitShift(DllStructGetData($t, 1, 9), -7) + DllStructGetData($t, 1, 10)
		If BitAND(DllStructGetData($t, 1, 6), 0x10) Then $lo += 10
	EndIf
	$pos = BP_FindStream($h, $lo, $sz)
	If $pos < 0 Then
		FileClose($h)
		Return 0
	EndIf
	FileSetPos($h, $pos, 0)
	DllStructSetData($t, 1, FileRead($h, 4096))
	FileClose($h)
	$a = BP_MpegHdr($t, 0)
	If $a[1] = 0 Then Return 0
	$v = BitAND(BitShift(DllStructGetData($t, 1, 2), 3), 3)
	$xo = 4 + (BitAND(DllStructGetData($t, 1, 2), 1) ? 0 : 2) + (($v = 3) ? ($a[4] = 1 ? 17 : 32) : ($a[4] = 1 ? 9 : 17)) ; header (+ CRC) + side info
	$id = DllStructGetData(DllStructCreate("char[4]", DllStructGetPtr($t) + $xo), 1)
	If ($id = "Xing" Or $id = "Info") And BitAND(DllStructGetData($t, 1, $xo + 8), 1) Then ; flag "frame count present"
		$fr = BP_BE32($t, $xo + 8)
		If $fr > 0 Then Return $fr * $a[3] / $a[2]
	EndIf
	Return ($sz - $pos) * 8 / $a[1] ; CBR estimate
EndFunc   ;==>BP_LenMp3
Func BP_LenWav($f)
	Local $h = FileOpen($f, 16)
	If $h = -1 Then Return 0
	Local $t = DllStructCreate("byte[4096]"), $p = 12, $br = 0, $dl = 0, $id, $sz, $ptr = DllStructGetPtr($t), $fs = FileGetSize($f)
	DllStructSetData($t, 1, FileRead($h, 4096))
	FileClose($h)
	While $p < 4000
		$id = DllStructGetData(DllStructCreate("char[4]", $ptr + $p), 1)
		$sz = DllStructGetData(DllStructCreate("dword", $ptr + $p + 4), 1)
		If $id = "fmt " Then $br = DllStructGetData(DllStructCreate("dword", $ptr + $p + 16), 1)
		If $id = "data" Then
			$dl = $sz
			If $dl = 0 Or $dl > $fs Then $dl = $fs - $p - 8
			ExitLoop
		EndIf
		$p += 8 + $sz + BitAND($sz, 1)
	WEnd
	Return $br > 0 ? $dl / $br : 0
EndFunc   ;==>BP_LenWav
Func BP_LenMp4($f) ; walks the top-level boxes to "moov", its first child "mvhd" holds timescale + duration
	Local $h = FileOpen($f, 16)
	If $h = -1 Then Return 0
	Local $size = FileGetSize($f), $pos = 0, $t = DllStructCreate("byte[64]"), $bs, $hL, $typ, $ts, $du, $k, $b
	For $k = 1 To 64
		FileSetPos($h, $pos, 0)
		$b = FileRead($h, 16)
		If @error Or BinaryLen($b) < 16 Then ExitLoop
		DllStructSetData($t, 1, $b)
		$bs = BP_BE32($t, 0)
		$typ = DllStructGetData(DllStructCreate("char[4]", DllStructGetPtr($t) + 4), 1)
		$hL = 8
		If $bs = 1 Then ; 64-bit box size
			$bs = BP_BE32($t, 8) * 4294967296 + BP_BE32($t, 12)
			$hL = 16
		EndIf
		If $typ = "moov" Then
			FileSetPos($h, $pos + $hL, 0)
			DllStructSetData($t, 1, FileRead($h, 64))
			FileClose($h)
			If DllStructGetData(DllStructCreate("char[4]", DllStructGetPtr($t) + 4), 1) <> "mvhd" Then Return 0
			If DllStructGetData($t, 1, 9) = 1 Then ; version 1: 64-bit duration
				$ts = BP_BE32($t, 28)
				$du = BP_BE32($t, 32) * 4294967296 + BP_BE32($t, 36)
			Else
				$ts = BP_BE32($t, 20)
				$du = BP_BE32($t, 24)
			EndIf
			Return $ts > 0 ? $du / $ts : 0
		EndIf
		If $bs < 8 Then ExitLoop
		$pos += $bs
		If $pos >= $size Then ExitLoop
	Next
	FileClose($h)
	Return 0
EndFunc   ;==>BP_LenMp4
Func BP_LenAvi($f) ; "avih": microseconds per frame x total frames
	Local $h = FileOpen($f, 16)
	If $h = -1 Then Return 0
	Local $t = DllStructCreate("byte[64]"), $p = DllStructGetPtr($t)
	DllStructSetData($t, 1, FileRead($h, 64))
	FileClose($h)
	If DllStructGetData(DllStructCreate("char[4]", $p), 1) <> "RIFF" Then Return 0
	If DllStructGetData(DllStructCreate("char[4]", $p + 8), 1) <> "AVI " Then Return 0
	If DllStructGetData(DllStructCreate("char[4]", $p + 24), 1) <> "avih" Then Return 0
	Return DllStructGetData(DllStructCreate("dword", $p + 48), 1) * DllStructGetData(DllStructCreate("dword", $p + 32), 1) / 1000000
EndFunc   ;==>BP_LenAvi
Func BP_LenMci($f) ; last resort for audio: let MCI open the file just to ask for its length
	BP_Mci("close bplen")
	BP_Mci('open "' & $f & '" alias bplen')
	If $BP_iErr Then Return 0
	BP_Mci("set bplen time format milliseconds")
	Local $l = Number(BP_Mci("status bplen length")) / 1000
	BP_Mci("close bplen")
	Return $l
EndFunc   ;==>BP_LenMci
Func BP_Id3Tags($f) ; [title, artist, album] from an ID3v2.3 / 2.4 tag (mp3), without the Shell
	Local $r[3] = ["", "", ""], $h = FileOpen($f, 16)
	If $h = -1 Then Return $r
	Local $t = DllStructCreate("byte[10]"), $ver, $tag, $b, $ln, $p = 0, $fid, $sz, $tb, $ptr
	DllStructSetData($t, 1, FileRead($h, 10))
	$ver = DllStructGetData($t, 1, 4)
	If DllStructGetData(DllStructCreate("char[3]", DllStructGetPtr($t)), 1) <> "ID3" Or ($ver <> 3 And $ver <> 4) Then
		FileClose($h)
		Return $r
	EndIf
	$tag = BitShift(DllStructGetData($t, 1, 7), -21) + BitShift(DllStructGetData($t, 1, 8), -14) + BitShift(DllStructGetData($t, 1, 9), -7) + DllStructGetData($t, 1, 10)
	$b = FileRead($h, _Min($tag, 262144))
	FileClose($h)
	$ln = BinaryLen($b)
	If $ln < 11 Then Return $r
	$tb = DllStructCreate("byte[" & $ln & "]")
	DllStructSetData($tb, 1, $b)
	$ptr = DllStructGetPtr($tb)
	While $p + 10 <= $ln
		If DllStructGetData($tb, 1, $p + 1) = 0 Then ExitLoop ; padding
		$fid = DllStructGetData(DllStructCreate("char[4]", $ptr + $p), 1)
		If $ver = 4 Then ; syncsafe frame size
			$sz = BitShift(DllStructGetData($tb, 1, $p + 5), -21) + BitShift(DllStructGetData($tb, 1, $p + 6), -14) + BitShift(DllStructGetData($tb, 1, $p + 7), -7) + DllStructGetData($tb, 1, $p + 8)
		Else
			$sz = BP_BE32($tb, $p + 4)
		EndIf
		If $sz <= 0 Or $p + 10 + $sz > $ln Then ExitLoop
		If $fid = "TIT2" Then $r[0] = BP_Id3Dec($tb, $p + 10, $sz)
		If $fid = "TPE1" Then $r[1] = BP_Id3Dec($tb, $p + 10, $sz)
		If $fid = "TALB" Then $r[2] = BP_Id3Dec($tb, $p + 10, $sz)
		$p += 10 + $sz
	WEnd
	Return $r
EndFunc   ;==>BP_Id3Tags
Func BP_Id3Dec($t, $off, $sz) ; text frame: 1 encoding byte + text (0 = ANSI, 1 = UTF-16 + BOM, 2 = UTF-16BE, 3 = UTF-8)
	If $sz < 2 Then Return ""
	Local $e = DllStructGetData($t, 1, $off + 1), $x = DllStructGetData(DllStructCreate("byte[" & ($sz - 1) & "]", DllStructGetPtr($t) + $off + 1), 1), $r, $bom
	Switch $e
		Case 0
			$r = BinaryToString($x, 1)
		Case 1
			$bom = Hex(BinaryMid($x, 1, 2))
			If $bom = "FEFF" Then
				$r = BinaryToString(BinaryMid($x, 3), 3)
			Else
				$r = BinaryToString($bom = "FFFE" ? BinaryMid($x, 3) : $x, 2)
			EndIf
		Case 2
			$r = BinaryToString($x, 3)
		Case Else
			$r = BinaryToString($x, 4)
	EndSwitch
	Return StringStripWS(StringReplace($r, Chr(0), ""), 3)
EndFunc   ;==>BP_Id3Dec
Func BP_Tags($f)
	Local $oS = 0, $p, $oF, $oI, $ti = "", $ar = "", $a
	If Not $BP_fNoShell Then
		$oS = ObjCreate("Shell.Application")
		If Not IsObj($oS) Then
			$BP_fNoShell = True
			BP_Log("no Shell.Application - native tag reader enabled")
		EndIf
	EndIf
	If IsObj($oS) Then
		$p = StringInStr($f, "\", 0, -1)
		If $p > 1 Then
			$oF = $oS.Namespace(StringLeft($f, $p - 1))
			If IsObj($oF) Then
				$oI = $oF.ParseName(StringMid($f, $p + 1))
				If IsObj($oI) Then
					$ti = BP_Cl($oF.GetDetailsOf($oI, 21))
					$ar = BP_Cl($oF.GetDetailsOf($oI, 13))
				EndIf
			EndIf
		EndIf
	EndIf
	If $ti = "" And StringLower(StringRight($f, 4)) = ".mp3" Then
		$a = BP_Id3Tags($f)
		$ti = $a[0]
		$ar = $a[1]
	EndIf
	If $ti = "" Then Return BP_Name($f)
	Return $ar <> "" ? $ar & " " & ChrW(8211) & " " & $ti : $ti
EndFunc   ;==>BP_Tags
Func BP_Cl($s) ; strip hidden unicode direction marks
	Return StringStripWS(StringRegExpReplace($s, "[\x{200E}\x{200F}\x{202A}-\x{202E}]", ""), 3)
EndFunc   ;==>BP_Cl
; works for mp3 / wav / wma - whatever Explorer shows in the "Length" column
Func BP_MP3_GetLengthSec($sFile)
	If Not FileExists($sFile) Then Return 0
	If Not $BP_fNoShell Then
		Local $oShell = ObjCreate("Shell.Application")
		If IsObj($oShell) Then
			Local $iSlash = StringInStr($sFile, "\", 0, -1)
			If $iSlash > 1 Then
				Local $oFolder = $oShell.Namespace(StringLeft($sFile, $iSlash - 1))
				If IsObj($oFolder) Then
					Local $oFile = $oFolder.ParseName(StringTrimLeft($sFile, $iSlash))
					If IsObj($oFile) Then
						Local $sTime = StringRegExpReplace($oFolder.GetDetailsOf($oFile, 27), "[^\d:]", "")
						If $sTime <> "" Then
							Local $a = StringSplit($sTime, ":")
							Local $n = ($a[0] = 2) ? ($a[1] * 60 + $a[2]) : (($a[0] = 3) ? ($a[1] * 3600 + $a[2] * 60 + $a[3]) : 0)
							If $n > 0 Then Return $n
						EndIf
						Local $v = Number($oFile.ExtendedProperty("System.Media.Duration"))
						If $v > 0 Then Return Round($v / 10000000)
					EndIf
				EndIf
			EndIf
		Else
			$BP_fNoShell = True
			BP_Log("no Shell.Application - native length reader enabled")
		EndIf
	EndIf
	Return BP_LenNative($sFile)
EndFunc   ;==>BP_MP3_GetLengthSec
; ================= current BrAiNPlay helpers =================
Func BP_B($t, $x, $y, $w, $h, $c, $fs = 11)
	Local $id = GUICtrlCreateLabel($t, $x, $y, $w, $h, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetBkColor($id, $BP_PNL)
	GUICtrlSetColor($id, $c)
	GUICtrlSetFont($id, $fs, 700)
	Return $id
EndFunc   ;==>BP_B
Func BP_ToTray() ; minimize into the tray (icon only while hidden)
	If $BP_fTray Then Return
	$BP_fTray = True
	BP_VidApply() ; video window follows (hidden while in tray)
	GUISetState(@SW_HIDE, $hGUI)
	TraySetState($TRAY_ICONSTATE_SHOW)
	BP_Tip()
EndFunc   ;==>BP_ToTray
Func BP_FromTray()
	If Not $BP_fTray Then Return
	$BP_fTray = False
	TraySetState($TRAY_ICONSTATE_HIDE)
	GUISetState(@SW_SHOW, $hGUI)
	GUISetState(@SW_RESTORE, $hGUI)
	WinActivate($hGUI)
	BP_VidApply()
EndFunc   ;==>BP_FromTray
Func BP_Tip() ; tray tooltip = current track
	TraySetToolTip($BP_fPlay ? StringLeft($BP_sNow, 120) : $APP_TITLE)
EndFunc   ;==>BP_Tip
Func BP_Name($f)
	Return StringRegExpReplace($f, "^.*\\|\.[^.]*$", "")
EndFunc   ;==>BP_Name
Func BP_T($s)
	Return StringFormat("%02d:%02d", Int($s / 60), Mod(Int($s), 60))
EndFunc   ;==>BP_T
Func BP_Err($oError)
	SetError(1)
EndFunc   ;==>BP_Err
Func BP_Log($s) ; %APPDATA%\BrAiNPlay\brainplay.log
;~ 	FileWriteLine($BP_sApp & "\brainplay.log", @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & "  " & $s)
	Return
EndFunc   ;==>BP_Log
Func BP_WmpErr() ; last WMP error text (if any)
	Local $e = $BP_oWMP.Error
	If Not IsObj($e) Then Return ""
	If $e.errorCount < 1 Then Return ""
	Local $it = $e.Item(0)
	If Not IsObj($it) Then Return ""
	Return $it.errorDescription
EndFunc   ;==>BP_WmpErr
Func BP_MciErr($n) ; MCI error code -> text
	Local $t = DllStructCreate("wchar[256]")
	DllCall("winmm.dll", "int", "mciGetErrorStringW", "dword", $n, "ptr", DllStructGetPtr($t), "uint", 255)
	Return $n & " " & DllStructGetData($t, 1)
EndFunc   ;==>BP_MciErr
Func BP_Quit()
	If $BP_fQDone Then Return ; runs twice (explicit call + exit handler); the second time the video window and WMP are already gone
	$BP_fQDone = True
	BP_WmpKeys(False)
	BP_MediaKeys(False)
	BP_Cursor(True)
	BP_KeepAwake(False)
	If IsObj($BP_oWMP) Then
		$BP_oWMP.fullScreen = False
		$BP_oWMP.controls.stop()
		$BP_oWMP = 0 ; release the control before the windows are deleted
	EndIf
	BP_FFKill()
	BP_Mci("close bp")
	IniWrite($BP_sIni, "player", "video", $BP_fVidOn ? "1" : "0")
	IniWrite($BP_sIni, "player", "full", $BP_fFull ? "1" : "0")
	FileDelete($BP_sTmp)
	IniWrite($BP_sIni, "player", "vol", $BP_iVol)
	IniWrite($BP_sIni, "player", "bal", $BP_iBal)
	IniWrite($BP_sIni, "player", "shuf", $BP_fShuf ? "1" : "0")
	IniWrite($BP_sIni, "player", "loop", $BP_fLoop ? "1" : "0")
	If UBound($BP_aPl) Then
		BP_SaveList($BP_sLast)
	Else
		FileDelete($BP_sLast)
	EndIf
EndFunc   ;==>BP_Quit
