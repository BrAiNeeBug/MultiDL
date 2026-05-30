#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=multidl.ico
#AutoIt3Wrapper_Outfile_x64=MultiDL.exe
#AutoIt3Wrapper_Add_Includes=n
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
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

; ---- Konstanten ----
Global Const $APP_TITLE = "BrAiNee's MultiDL v6"
Global Const $BIN_DIR = @ScriptDir & "\bin"
Global Const $DL_DIR = @ScriptDir & "\MultiDL-Downloads"
Global Const $YTDLP_EXE = $BIN_DIR & "\yt-dlp.exe"
Global Const $FFMPEG_EXE = $BIN_DIR & "\ffmpeg.exe"
Global Const $CLR_BG = 0x0F0F0F
Global Const $CLR_PANEL = 0x1A1A1A
Global Const $CLR_ACCENT = 0xFF0000
Global Const $CLR_TEXT = 0xF0F0F0
Global Const $CLR_MUTED = 0x888888
Global Const $CLR_INPUT = 0x252525

; ---- Modus: False = Video, True = MP3 ----
Global $bMP3Mode = False
; ---- Playlist-Modus: False = einzelnes Video, True = ganze Playlist ----
Global $bPlaylistMode = False
; ---- CMD-Fenster sichtbar? ----
Global $bShowCMD = False
; ---- Aktueller yt-dlp Prozess Handle ----
Global $hDLProc = 0
; ---- Zuletzt heruntergeladene Datei (fuer Play-Button) ----
Global $sLastFile = ""

; ---- Startup Check ----
_StartupCheck()

; ---- GUI aufbauen ----
Local $hGUI = GUICreate($APP_TITLE, 560, 524, -1, -1, $WS_POPUP + $WS_BORDER)
GUISetBkColor($CLR_BG, $hGUI)

; Titelleiste
Local $hTitleBar = GUICtrlCreateLabel("", 0, 0, 560, 36)
GUICtrlSetBkColor($hTitleBar, $CLR_PANEL)

Local $hIcon = GUICtrlCreateLabel(">", 12, 8, 24, 22)
GUICtrlSetFont($hIcon, 13, 800, 0, "Segoe UI")
GUICtrlSetColor($hIcon, $CLR_ACCENT)
GUICtrlSetBkColor($hIcon, $CLR_PANEL)

Local $hTitleText = GUICtrlCreateLabel($APP_TITLE, 38, 9, 200, 20)
GUICtrlSetFont($hTitleText, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hTitleText, $CLR_TEXT)
GUICtrlSetBkColor($hTitleText, $CLR_PANEL)

; Live-Button in Titelleiste
Local $hBtnLive = GUICtrlCreateLabel(" LIVE ", 450, 8, 48, 20)
GUICtrlSetFont($hBtnLive, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnLive, $CLR_TEXT)
GUICtrlSetBkColor($hBtnLive, 0x660000)

Local $hClose = GUICtrlCreateLabel("x", 527, 8, 24, 22)
GUICtrlSetFont($hClose, 10, 700, 0, "Segoe UI")
GUICtrlSetColor($hClose, $CLR_MUTED)
GUICtrlSetBkColor($hClose, $CLR_PANEL)

; Trennlinie
Local $hLine = GUICtrlCreateLabel("", 0, 36, 560, 2)
GUICtrlSetBkColor($hLine, $CLR_ACCENT)

; ---- URL Eingabe ----
Local $hLabelURL = GUICtrlCreateLabel("Data URL:", 24, 58, 250, 18)
GUICtrlSetFont($hLabelURL, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLabelURL, $CLR_TEXT)
GUICtrlSetBkColor($hLabelURL, $CLR_BG)

Local $hInput = GUICtrlCreateEdit("", 24, 80, 512, 48, $ES_MULTILINE + $ES_AUTOVSCROLL + $WS_VSCROLL)
GUICtrlSetFont($hInput, 9, 400, 0, "Consolas")
GUICtrlSetColor($hInput, $CLR_TEXT)
GUICtrlSetBkColor($hInput, $CLR_INPUT)

; ---- Bereinigter Link ----
Local $hLabelClean = GUICtrlCreateLabel("Cleaned Link:", 24, 146, 200, 18)
GUICtrlSetFont($hLabelClean, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLabelClean, $CLR_MUTED)
GUICtrlSetBkColor($hLabelClean, $CLR_BG)

Local $hCleanDisplay = GUICtrlCreateLabel("---", 24, 166, 512, 18)
GUICtrlSetFont($hCleanDisplay, 9, 400, 0, "Consolas")
GUICtrlSetColor($hCleanDisplay, 0x4FC3F7)
GUICtrlSetBkColor($hCleanDisplay, $CLR_BG)

; ---- Trennlinie ----
Local $hLine2 = GUICtrlCreateLabel("", 24, 198, 512, 1)
GUICtrlSetBkColor($hLine2, 0x2A2A2A)

; ---- Format Toggle ----
Local $hLabelFormat = GUICtrlCreateLabel("Format:", 24, 212, 60, 20)
GUICtrlSetFont($hLabelFormat, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLabelFormat, $CLR_MUTED)
GUICtrlSetBkColor($hLabelFormat, $CLR_BG)

Local $hToggleVideo = GUICtrlCreateLabel("  Video(MP4)  ", 88, 207, 80, 26)
GUICtrlSetFont($hToggleVideo, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hToggleVideo, $CLR_TEXT)
GUICtrlSetBkColor($hToggleVideo, $CLR_ACCENT)

Local $hToggleMP3 = GUICtrlCreateLabel("  Audio(MP3)  ", 168, 207, 80, 26)
GUICtrlSetFont($hToggleMP3, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hToggleMP3, $CLR_MUTED)
GUICtrlSetBkColor($hToggleMP3, 0x222222)

Local $hModeInfo = GUICtrlCreateLabel("(best video quality)", 258, 212, 280, 18)
GUICtrlSetFont($hModeInfo, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hModeInfo, $CLR_MUTED)
GUICtrlSetBkColor($hModeInfo, $CLR_BG)

; ---- Playlist Toggle ----
Local $hLabelPlaylist = GUICtrlCreateLabel("Mode:", 24, 244, 60, 20)
GUICtrlSetFont($hLabelPlaylist, 9, 600, 0, "Segoe UI")
GUICtrlSetColor($hLabelPlaylist, $CLR_MUTED)
GUICtrlSetBkColor($hLabelPlaylist, $CLR_BG)

Local $hToggleSingle = GUICtrlCreateLabel("  Single  ", 88, 239, 90, 26)
GUICtrlSetFont($hToggleSingle, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hToggleSingle, $CLR_TEXT)
GUICtrlSetBkColor($hToggleSingle, $CLR_ACCENT)

Local $hTogglePlaylist = GUICtrlCreateLabel("  Playlist  ", 178, 239, 90, 26)
GUICtrlSetFont($hTogglePlaylist, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hTogglePlaylist, $CLR_MUTED)
GUICtrlSetBkColor($hTogglePlaylist, 0x222222)

Local $hPlaylistInfo = GUICtrlCreateLabel("(download single file)", 278, 244, 260, 18)
GUICtrlSetFont($hPlaylistInfo, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hPlaylistInfo, $CLR_MUTED)
GUICtrlSetBkColor($hPlaylistInfo, $CLR_BG)

; ---- Buttons ----
Local $hBtnDownload = GUICtrlCreateButton("Start", 24, 282, 224, 38)
GUICtrlSetFont($hBtnDownload, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnDownload, $CLR_TEXT)
GUICtrlSetBkColor($hBtnDownload, 0x00AA44)

Local $hBtnCMD = GUICtrlCreateButton("CMD: OFF", 256, 282, 84, 38)
GUICtrlSetFont($hBtnCMD, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnCMD, $CLR_MUTED)
GUICtrlSetBkColor($hBtnCMD, 0x1A1A1A)

Local $hBtnPaste = GUICtrlCreateButton("PasteStart", 348, 282, 110, 38)
GUICtrlSetFont($hBtnPaste, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnPaste, $CLR_TEXT)
GUICtrlSetBkColor($hBtnPaste, 0x1E3A1E)

Local $hBtnUpdate = GUICtrlCreateButton("Update", 466, 282, 70, 38)
GUICtrlSetFont($hBtnUpdate, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnUpdate, $CLR_MUTED)
GUICtrlSetBkColor($hBtnUpdate, 0x1A1A2A)

; ---- Fortschritts-Bereich ----
Local $hLine3 = GUICtrlCreateLabel("", 24, 334, 512, 1)
GUICtrlSetBkColor($hLine3, 0x2A2A2A)

Local $hProgLabel = GUICtrlCreateLabel("Ready.", 24, 342, 460, 16)
GUICtrlSetFont($hProgLabel, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hProgLabel, $CLR_MUTED)
GUICtrlSetBkColor($hProgLabel, $CLR_BG)

Local $hProgPct = GUICtrlCreateLabel("", 490, 342, 46, 16)
GUICtrlSetFont($hProgPct, 8, 700, 0, "Segoe UI")
GUICtrlSetColor($hProgPct, $CLR_ACCENT)
GUICtrlSetBkColor($hProgPct, $CLR_BG)

Local $hProgBG = GUICtrlCreateLabel("", 24, 364, 512, 12)
GUICtrlSetBkColor($hProgBG, 0x222222)

Local $hProgBar = GUICtrlCreateLabel("", 24, 364, 0, 12)
GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)

; ---- Statuszeile ----
Local $hStatus = GUICtrlCreateLabel("Ready.", 0, 492, 560, 32)
GUICtrlSetFont($hStatus, 8, 400, 0, "Segoe UI")
GUICtrlSetColor($hStatus, $CLR_MUTED)
GUICtrlSetBkColor($hStatus, $CLR_PANEL)
GUICtrlSetStyle($hStatus, $SS_CENTER)

; ---- Play-Bereich ----
Local $hLine4 = GUICtrlCreateLabel("", 24, 386, 512, 1)
GUICtrlSetBkColor($hLine4, 0x2A2A2A)

Local $hBtnPlay = GUICtrlCreateLabel("> Play last File", 24, 398, 242, 36)
GUICtrlSetFont($hBtnPlay, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnPlay, $CLR_TEXT)
GUICtrlSetBkColor($hBtnPlay, 0x1A3A1A)

Local $hBtnFolder = GUICtrlCreateLabel("[>] View Downloads", 278, 398, 258, 36)
GUICtrlSetFont($hBtnFolder, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($hBtnFolder, $CLR_MUTED)
GUICtrlSetBkColor($hBtnFolder, 0x1A1A2A)

Local $hPlayLabel = GUICtrlCreateLabel("No download completed yet.", 24, 440, 512, 16)
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
GUICtrlSetBkColor($hLiveBtnStart, 0x880000)
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
Local $hLiveProgLabel = GUICtrlCreateLabel("Ready.", 24, 268, 460, 16)
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

; ---- Fenster anzeigen ----
GUISetState(@SW_SHOW, $hGUI)

; ---- Hauptschleife ----
Local $bDragging = False
Local $iDragX, $iDragY
Local $iPosX, $iPosY
Local $bLiveView = False
; Pulse fuer Live-Balken
Local $iPulse = 0, $iPulseDir = 1

While 1
	Local $aMsg = GUIGetMsg(1)
	Local $iMsg = $aMsg[0]

	; ---- Fortschritt lesen wenn Download laeuft ----
	If $hDLProc <> 0 Then
		If $bLiveView Then
			_ReadLiveProgress($hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart)
		Else
			_ReadProgress($hProgBar, $hProgLabel, $hProgPct, $hStatus)
		EndIf
	EndIf

	Select
		Case $iMsg = $GUI_EVENT_CLOSE
			ExitLoop

		Case $iMsg = $GUI_EVENT_PRIMARYDOWN
			Local $aCursorPos = MouseGetPos()
			Local $aWinPos = WinGetPos($hGUI)
			Local $iRelX = $aCursorPos[0] - $aWinPos[0]
			Local $iRelY = $aCursorPos[1] - $aWinPos[1]
			; X-Button
			If $iRelX >= 518 And $iRelX <= 555 And $iRelY >= 0 And $iRelY <= 36 Then
				ExitLoop
			EndIf
			; LIVE-Button (X=444..502, Y=0..36)
			If $iRelX >= 444 And $iRelX <= 502 And $iRelY >= 0 And $iRelY <= 36 And $hDLProc = 0 Then
				If Not $bLiveView Then
					$bLiveView = True
					GUICtrlSetBkColor($hBtnLive, $CLR_ACCENT)
					_ShowNormalControls($GUI_HIDE, $hLabelURL, $hInput, $hLabelClean, $hCleanDisplay, $hLine2, $hLabelFormat, $hToggleVideo, $hToggleMP3, $hModeInfo, $hLabelPlaylist, $hToggleSingle, $hTogglePlaylist, $hPlaylistInfo, $hBtnDownload, $hBtnCMD, $hBtnPaste, $hBtnUpdate, $hLine3, $hProgLabel, $hProgPct, $hProgBG, $hProgBar, $hLine4, $hBtnPlay, $hBtnFolder, $hPlayLabel, $hStatus)
					_ShowLiveControls($GUI_SHOW, $hLiveBanner, $hLiveTitle, $hLiveLabelURL, $hLiveInput, $hLiveInfo, $hLiveBtnStart, $hLiveBtnPaste, $hLiveLine, $hLiveProgLabel, $hLiveProgSize, $hLiveProgBG, $hLiveProgBar)
				Else
					$bLiveView = False
					GUICtrlSetBkColor($hBtnLive, 0x660000)
					_ShowLiveControls($GUI_HIDE, $hLiveBanner, $hLiveTitle, $hLiveLabelURL, $hLiveInput, $hLiveInfo, $hLiveBtnStart, $hLiveBtnPaste, $hLiveLine, $hLiveProgLabel, $hLiveProgSize, $hLiveProgBG, $hLiveProgBar)
					_ShowNormalControls($GUI_SHOW, $hLabelURL, $hInput, $hLabelClean, $hCleanDisplay, $hLine2, $hLabelFormat, $hToggleVideo, $hToggleMP3, $hModeInfo, $hLabelPlaylist, $hToggleSingle, $hTogglePlaylist, $hPlaylistInfo, $hBtnDownload, $hBtnCMD, $hBtnPaste, $hBtnUpdate, $hLine3, $hProgLabel, $hProgPct, $hProgBG, $hProgBar, $hLine4, $hBtnPlay, $hBtnFolder, $hPlayLabel, $hStatus)
				EndIf
			ElseIf $iRelY < 36 Then
				$bDragging = True
				$iDragX = $aCursorPos[0]
				$iDragY = $aCursorPos[1]
				$iPosX = $aWinPos[0]
				$iPosY = $aWinPos[1]
			EndIf

		Case $iMsg = $GUI_EVENT_PRIMARYUP
			$bDragging = False

		Case $iMsg = $GUI_EVENT_MOUSEMOVE
			If $bDragging Then
				Local $aCur = MouseGetPos()
				WinMove($hGUI, "", $iPosX + ($aCur[0] - $iDragX), $iPosY + ($aCur[1] - $iDragY))
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
				GUICtrlSetData($hLiveProgLabel, "Stopped.")
				GUICtrlSetData($hLiveProgSize, "")
				GUICtrlSetData($hLiveBtnStart, "Start Live")
				GUICtrlSetBkColor($hLiveBtnStart, 0x880000)
			Else
				Local $sRaw = GUICtrlRead($hLiveInput)
				$sRaw = StringStripWS($sRaw, 3)
				If $sRaw = "" Then
					GUICtrlSetData($hLiveProgLabel, "No URL entered.")
				Else
					_StartLive($sRaw, $hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart)
				EndIf
			EndIf

			; ---- Live PasteStart ----
		Case $iMsg = $hLiveBtnPaste
			If $hDLProc <> 0 Then
				GUICtrlSetData($hLiveProgLabel, "Stop first!")
			Else
				Local $sClip = ClipGet()
				If $sClip = "" Then
					GUICtrlSetData($hLiveProgLabel, "Clipboard empty.")
				Else
					GUICtrlSetData($hLiveInput, $sClip)
					_StartLive($sClip, $hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart)
				EndIf
			EndIf

			; Toggle: Video
		Case $iMsg = $hToggleVideo
			If $bMP3Mode Then
				$bMP3Mode = False
				GUICtrlSetBkColor($hToggleVideo, $CLR_ACCENT)
				GUICtrlSetColor($hToggleVideo, $CLR_TEXT)
				GUICtrlSetBkColor($hToggleMP3, 0x222222)
				GUICtrlSetColor($hToggleMP3, $CLR_MUTED)
				GUICtrlSetData($hModeInfo, "(best video quality)")
				_SetStatus($hStatus, "Modus: Video", $CLR_MUTED)
			EndIf

			; Toggle: MP3
		Case $iMsg = $hToggleMP3
			If Not $bMP3Mode Then
				$bMP3Mode = True
				GUICtrlSetBkColor($hToggleMP3, $CLR_ACCENT)
				GUICtrlSetColor($hToggleMP3, $CLR_TEXT)
				GUICtrlSetBkColor($hToggleVideo, 0x222222)
				GUICtrlSetColor($hToggleVideo, $CLR_MUTED)
				GUICtrlSetData($hModeInfo, "(best audio quality)")
				_SetStatus($hStatus, "Modus: Audio", $CLR_MUTED)
			EndIf

			; Toggle: Einzeln
		Case $iMsg = $hToggleSingle
			If $bPlaylistMode Then
				$bPlaylistMode = False
				GUICtrlSetBkColor($hToggleSingle, $CLR_ACCENT)
				GUICtrlSetColor($hToggleSingle, $CLR_TEXT)
				GUICtrlSetBkColor($hTogglePlaylist, 0x222222)
				GUICtrlSetColor($hTogglePlaylist, $CLR_MUTED)
				GUICtrlSetData($hPlaylistInfo, "(download single file)")
				_SetStatus($hStatus, "Modus: Single File", $CLR_MUTED)
				GUICtrlSetState($hBtnPlay, $GUI_SHOW)
				GUICtrlSetState($hBtnFolder, $GUI_SHOW)
				GUICtrlSetState($hPlayLabel, $GUI_SHOW)
				GUICtrlSetState($hLine4, $GUI_SHOW)
			EndIf

			; Toggle: Playlist
		Case $iMsg = $hTogglePlaylist
			If Not $bPlaylistMode Then
				$bPlaylistMode = True
				GUICtrlSetBkColor($hTogglePlaylist, $CLR_ACCENT)
				GUICtrlSetColor($hTogglePlaylist, $CLR_TEXT)
				GUICtrlSetBkColor($hToggleSingle, 0x222222)
				GUICtrlSetColor($hToggleSingle, $CLR_MUTED)
				GUICtrlSetData($hPlaylistInfo, "(download all files)")
				_SetStatus($hStatus, "Modus: Playlist", $CLR_MUTED)
				GUICtrlSetState($hBtnPlay, $GUI_HIDE)
				GUICtrlSetState($hBtnFolder, $GUI_HIDE)
				GUICtrlSetState($hPlayLabel, $GUI_HIDE)
				GUICtrlSetState($hLine4, $GUI_HIDE)
			EndIf

			; CMD-Fenster Toggle
		Case $iMsg = $hBtnCMD
			$bShowCMD = Not $bShowCMD
			If $bShowCMD Then
				GUICtrlSetData($hBtnCMD, "CMD: ON")
				GUICtrlSetColor($hBtnCMD, $CLR_TEXT)
				GUICtrlSetBkColor($hBtnCMD, 0x1E3A1E)
			Else
				GUICtrlSetData($hBtnCMD, "CMD: OFF")
				GUICtrlSetColor($hBtnCMD, $CLR_MUTED)
				GUICtrlSetBkColor($hBtnCMD, 0x1A1A1A)
			EndIf

			; Download / Stop Toggle
		Case $iMsg = $hBtnDownload
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
				GUICtrlSetPos($hProgBar, 24, 364, 0, 12)
				GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
				GUICtrlSetData($hProgLabel, "Stopped.")
				GUICtrlSetData($hProgPct, "")
				_SetStatus($hStatus, "Download stopped.", 0xFFAA00)
				GUICtrlSetData($hBtnDownload, "Start")
				GUICtrlSetBkColor($hBtnDownload, 0x00AA44)
			Else
				Local $sRaw = GUICtrlRead($hInput)
				$sRaw = StringStripWS($sRaw, 3)
				If $sRaw = "" Then
					_SetStatus($hStatus, "NO Link.", 0xFFAA00)
				Else
					Local $sClean = _CleanURL($sRaw)
					GUICtrlSetData($hCleanDisplay, $sClean)
					_StartDownload($sClean, $hStatus, $hProgBar, $hProgLabel, $hProgPct)
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
					GUICtrlSetData($hCleanDisplay, $sClean)
					_StartDownload($sClean, $hStatus, $hProgBar, $hProgLabel, $hProgPct)
				EndIf
			EndIf

			; Datei abspielen
		Case $iMsg = $hBtnPlay
			If $sLastFile <> "" And FileExists($sLastFile) Then
				ShellExecute($sLastFile)
			ElseIf $sLastFile <> "" Then
				_SetStatus($hStatus, "File not found: " & $sLastFile, 0xFF5252)
			Else
				_SetStatus($hStatus, "No download completed yet.", 0xFFAA00)
			EndIf

			; Download-Ordner oeffnen
		Case $iMsg = $hBtnFolder
			ShellExecute($DL_DIR)

			; Update
		Case $iMsg = $hBtnUpdate
			If $hDLProc <> 0 Then
				_SetStatus($hStatus, "Stop download first!", 0xFFAA00)
			Else
				_UpdateTools($hStatus, $hProgBar, $hProgLabel, $hProgPct)
			EndIf

	EndSelect
WEnd

GUIDelete($hGUI)
Exit

; ============================================================
;  Show/Hide Normal Controls
; ============================================================
Func _ShowNormalControls($iState, $hLabelURL, $hInput, $hLabelClean, $hCleanDisplay, $hLine2, $hLabelFormat, $hToggleVideo, $hToggleMP3, $hModeInfo, $hLabelPlaylist, $hToggleSingle, $hTogglePlaylist, $hPlaylistInfo, $hBtnDownload, $hBtnCMD, $hBtnPaste, $hBtnUpdate, $hLine3, $hProgLabel, $hProgPct, $hProgBG, $hProgBar, $hLine4, $hBtnPlay, $hBtnFolder, $hPlayLabel, $hStatus)
	GUICtrlSetState($hLabelURL, $iState)
	GUICtrlSetState($hInput, $iState)
	GUICtrlSetState($hLabelClean, $iState)
	GUICtrlSetState($hCleanDisplay, $iState)
	GUICtrlSetState($hLine2, $iState)
	GUICtrlSetState($hLabelFormat, $iState)
	GUICtrlSetState($hToggleVideo, $iState)
	GUICtrlSetState($hToggleMP3, $iState)
	GUICtrlSetState($hModeInfo, $iState)
	GUICtrlSetState($hLabelPlaylist, $iState)
	GUICtrlSetState($hToggleSingle, $iState)
	GUICtrlSetState($hTogglePlaylist, $iState)
	GUICtrlSetState($hPlaylistInfo, $iState)
	GUICtrlSetState($hBtnDownload, $iState)
	GUICtrlSetState($hBtnCMD, $iState)
	GUICtrlSetState($hBtnPaste, $iState)
	GUICtrlSetState($hBtnUpdate, $iState)
	GUICtrlSetState($hLine3, $iState)
	GUICtrlSetState($hProgLabel, $iState)
	GUICtrlSetState($hProgPct, $iState)
	GUICtrlSetState($hProgBG, $iState)
	GUICtrlSetState($hProgBar, $iState)
	GUICtrlSetState($hLine4, $iState)
	GUICtrlSetState($hBtnPlay, $iState)
	GUICtrlSetState($hBtnFolder, $iState)
	GUICtrlSetState($hPlayLabel, $iState)
	GUICtrlSetState($hStatus, $iState)
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
	If Not $bPlaylistMode Then
		Local $iAmp = StringInStr($sURL, "&")
		If $iAmp > 0 Then $sURL = StringLeft($sURL, $iAmp - 1)
	EndIf
	Return $sURL
EndFunc   ;==>_CleanURL

; ============================================================
;  Live-View: yt-dlp starten, Datei oeffnen
; ============================================================
Func _StartLive($sURL, $hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart)
	$sURL = StringStripWS($sURL, 3)
	If Not StringRegExp($sURL, "(?i)^https?://") Then
		GUICtrlSetData($hLiveProgLabel, "Bad URL.")
		Return
	EndIf
	; Playlist-Parameter raus
	Local $iAmp = StringInStr($sURL, "&")
	If $iAmp > 0 Then $sURL = StringLeft($sURL, $iAmp - 1)

	GUICtrlSetPos($hLiveProgBar, 24, 290, 0, 10)
	GUICtrlSetData($hLiveProgLabel, "Starting...")
	GUICtrlSetData($hLiveProgSize, "")
	GUICtrlSetData($hLiveBtnStart, "Stop")
	GUICtrlSetBkColor($hLiveBtnStart, 0x444444)

	Local $sOutFile = $DL_DIR & "\_watch_live.mp4"
	Local $sCMD = '"' & $YTDLP_EXE & '" --no-playlist --no-part -f "best[ext=mp4]/best" --newline -o "' & $sOutFile & '" "' & $sURL & '"'

	If $bShowCMD Then Run('cmd.exe /k "' & $sCMD & '"', $DL_DIR, @SW_SHOW)
	$hDLProc = Run($sCMD, $DL_DIR, @SW_HIDE, 2)

	; Warten bis Datei existiert, dann Player
	GUICtrlSetData($hLiveProgLabel, "Waiting for file...")
	Local $iWait = 0
	Do
		Sleep(300)
		$iWait += 1
		GUIGetMsg()
	Until (FileExists($sOutFile) And FileGetSize($sOutFile) > 0) Or $iWait > 50
	If FileExists($sOutFile) And FileGetSize($sOutFile) > 0 Then
		ShellExecute($sOutFile)
		GUICtrlSetData($hLiveProgLabel, "Watching _watch_live.mp4 ...")
	Else
		GUICtrlSetData($hLiveProgLabel, "File not ready yet, download running...")
	EndIf
EndFunc   ;==>_StartLive

; ============================================================
;  Live-Fortschritt lesen
; ============================================================
Func _ReadLiveProgress($hLiveProgBar, $hLiveProgLabel, $hLiveProgSize, $hLiveBtnStart)
	Local $sLine = StdoutRead($hDLProc)
	If @error Then
		$hDLProc = 0
		GUICtrlSetPos($hLiveProgBar, 24, 290, 512, 10)
		GUICtrlSetData($hLiveProgLabel, "Done.")
		GUICtrlSetData($hLiveProgSize, "")
		GUICtrlSetData($hLiveBtnStart, "Start Live")
		GUICtrlSetBkColor($hLiveBtnStart, 0x880000)
		Return
	EndIf
	If $sLine = "" Then Return

	Local $aLines = StringSplit($sLine, @LF, 1)
	For $i = 1 To $aLines[0]
		Local $sTrimmed = StringStripWS($aLines[$i], 3)
		If StringLen($sTrimmed) < 4 Then ContinueLoop

		; Groesse aus [download]-Zeile
		Local $aSize = StringRegExp($sTrimmed, "\[download\]\s+([\d\.]+\s*(?:KiB|MiB|GiB))", 1)
		If Not @error And UBound($aSize) >= 1 Then
			GUICtrlSetData($hLiveProgSize, $aSize[0])
			Local $sShort = StringRegExpReplace($sTrimmed, "^\[download\]\s+", "")
			If StringLen($sShort) > 65 Then $sShort = StringLeft($sShort, 65) & "..."
			GUICtrlSetData($hLiveProgLabel, $sShort)
			; Pulsierender Balken
			Static Local $iPulse = 0, $iPulseDir = 1
			$iPulse += $iPulseDir * 24
			If $iPulse >= 480 Then $iPulseDir = -1
			If $iPulse <= 0 Then $iPulseDir = 1
			GUICtrlSetPos($hLiveProgBar, 24, 290, $iPulse, 10)
			ContinueLoop
		EndIf

		If StringInStr($sTrimmed, "ERROR") Then
			GUICtrlSetData($hLiveProgLabel, StringLeft($sTrimmed, 65))
			$hDLProc = 0
			GUICtrlSetData($hLiveBtnStart, "Start Live")
			GUICtrlSetBkColor($hLiveBtnStart, 0x880000)
		EndIf
	Next
EndFunc   ;==>_ReadLiveProgress

; ============================================================
;  yt-dlp starten (Video oder MP3)
; ============================================================
Func _StartDownload($sURL, $hStatusLabel, $hProgBar, $hProgLabel, $hProgPct)
	If Not FileExists($YTDLP_EXE) Then
		MsgBox(16, $APP_TITLE, "yt-dlp.exe not found!" & @CRLF & "needed in: " & $YTDLP_EXE)
		_SetStatus($hStatusLabel, "yt-dlp.exe not found!", 0xFF5252)
		Return
	EndIf
	If Not StringRegExp($sURL, "(?i)^https?://") Then
		_SetStatus($hStatusLabel, "Bad Link.", 0xFFAA00)
		Return
	EndIf

	GUICtrlSetPos($hProgBar, 24, 364, 0, 12)
	GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
	GUICtrlSetData($hProgLabel, "Starting Download...")
	GUICtrlSetData($hBtnDownload, "Stop")
	GUICtrlSetBkColor($hBtnDownload, 0xAA0000)
	GUICtrlSetData($hProgPct, "")
	$sLastFile = ""
	If Not $bPlaylistMode Then
		GUICtrlSetBkColor($hBtnPlay, 0x1A3A1A)
		GUICtrlSetColor($hBtnPlay, $CLR_TEXT)
		GUICtrlSetData($hPlayLabel, "Download running...")
		GUICtrlSetColor($hPlayLabel, $CLR_MUTED)
	EndIf

	Local $sCMD
	Local $sPlFlag = " --no-playlist"
	If $bPlaylistMode Then $sPlFlag = " --yes-playlist"

	If $bMP3Mode Then
		If Not FileExists($FFMPEG_EXE) Then
			MsgBox(16, $APP_TITLE, "ffmpeg.exe not found!" & @CRLF & "needed in: " & $FFMPEG_EXE)
			_SetStatus($hStatusLabel, "ffmpeg.exe not found!", 0xFF5252)
			Return
		EndIf
		_SetStatus($hStatusLabel, "MP3 Download started ...", 0x4FC3F7)
		$sCMD = '"' & $YTDLP_EXE & '" --ffmpeg-location "' & $BIN_DIR & '"' & $sPlFlag & ' -x --audio-format mp3 --audio-quality 0 --newline -o "' & $DL_DIR & '\%(title)s.%(ext)s" "' & $sURL & '"'
	Else
		_SetStatus($hStatusLabel, "Video Download started ...", 0x4FC3F7)
		$sCMD = '"' & $YTDLP_EXE & '" --ffmpeg-location "' & $BIN_DIR & '"' & $sPlFlag & ' -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4 --newline -o "' & $DL_DIR & '\%(title)s.%(ext)s" "' & $sURL & '"'
	EndIf

	If $bShowCMD Then Run('cmd.exe /k "' & $sCMD & '"', $DL_DIR, @SW_SHOW)
	$hDLProc = Run($sCMD, $DL_DIR, @SW_HIDE, 2)
EndFunc   ;==>_StartDownload

; ============================================================
;  Fortschritt aus yt-dlp Output lesen
; ============================================================
Func _ReadProgress($hProgBar, $hProgLabel, $hProgPct, $hStatus)
	Local $sLine = StdoutRead($hDLProc)
	If @error Then
		GUICtrlSetPos($hProgBar, 24, 364, 512, 12)
		GUICtrlSetBkColor($hProgBar, 0x00AA44)
		GUICtrlSetData($hProgPct, "100%")
		GUICtrlSetData($hProgLabel, "Download DONE!")
		_SetStatus($hStatus, "DONE! Saved to: " & $DL_DIR, 0x00AA44)
		If Not $bPlaylistMode Then
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
		EndIf
		$hDLProc = 0
		GUICtrlSetData($hBtnDownload, "Start")
		GUICtrlSetBkColor($hBtnDownload, 0x00AA44)
		Return
	EndIf
	If $sLine = "" Then Return

	Local $aLines = StringSplit($sLine, @LF, 1)
	For $i = 1 To $aLines[0]
		Local $sTrimmed = StringStripWS($aLines[$i], 3)
		If StringLen($sTrimmed) > 3 Then
			_ParseProgressLine($sTrimmed, $hProgBar, $hProgLabel, $hProgPct, $hStatus)
		EndIf
	Next
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
		GUICtrlSetPos($hProgBar, 24, 364, $iWidth, 12)
		GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
		GUICtrlSetData($hProgPct, StringFormat("%.0f%%", $fPct))
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
		GUICtrlSetData($hProgLabel, "Lade: " & $sFile)
		Return
	EndIf

	Local $aMerge = StringRegExp($sLine, '\[Merger\].*?"(.+?)"', 1)
	If Not @error And UBound($aMerge) >= 1 Then
		Local $sMergedFile = StringStripWS($aMerge[0], 3)
		If Not StringRegExp($sMergedFile, "^[A-Za-z]:\\") Then
			$sMergedFile = $DL_DIR & "\" & $sMergedFile
		EndIf
		$sLastFile = $sMergedFile
		GUICtrlSetData($hProgLabel, "Merging / Converting...")
		GUICtrlSetPos($hProgBar, 24, 364, 490, 12)
		GUICtrlSetData($hProgPct, "~99%")
		Return
	EndIf
	If StringInStr($sLine, "[Merger]") Or StringInStr($sLine, "Merging") Or StringInStr($sLine, "ffmpeg") Then
		GUICtrlSetData($hProgLabel, "Merging / Converting...")
		GUICtrlSetPos($hProgBar, 24, 364, 490, 12)
		GUICtrlSetData($hProgPct, "~99%")
		Return
	EndIf

	If StringInStr($sLine, "ERROR") Then
		GUICtrlSetBkColor($hProgBar, 0xFF5252)
		If StringLen($sLine) > 65 Then
			GUICtrlSetData($hProgLabel, StringLeft($sLine, 65) & "...")
		Else
			GUICtrlSetData($hProgLabel, $sLine)
		EndIf
		_SetStatus($hStatus, "ERROR! Look CMD-Window for Details.", 0xFF5252)
		$hDLProc = 0
		GUICtrlSetData($hBtnDownload, "Start")
		GUICtrlSetBkColor($hBtnDownload, 0x00AA44)
		Return
	EndIf
EndFunc   ;==>_ParseProgressLine


; ============================================================
;  Startup Check: yt-dlp.exe und ffmpeg.exe pruefen & laden
; ============================================================
Func _StartupCheck()
	If Not FileExists($BIN_DIR) Then DirCreate($BIN_DIR)
	If Not FileExists($DL_DIR) Then DirCreate($DL_DIR)
	Local $bNeedYtdlp = Not FileExists($YTDLP_EXE)
	Local $bNeedFfmpeg = Not FileExists($FFMPEG_EXE)
	If Not $bNeedYtdlp And Not $bNeedFfmpeg Then Return

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
		GUICtrlSetData($hProgInfo, "Checking latest 7-Zip version...")
		Local $s7zrURL = _Get7zrURL()
		Local $aTag7z = StringRegExp($s7zrURL, "/download/([^/]+)/", 1)
		Local $sTag7z = (Not @error And UBound($aTag7z) >= 1) ? $aTag7z[0] : "26.01"
		Local $sVer7z = StringReplace($sTag7z, ".", "")
		Local $s7zaURL = "https://github.com/ip7z/7zip/releases/download/" & $sTag7z & "/7z" & $sVer7z & "-extra.7z"

		If Not FileExists($BIN_DIR & "\7zr.exe") Or FileGetSize($BIN_DIR & "\7zr.exe") < 100000 Then
			GUICtrlSetData($hProgInfo, "Downloading 7zr.exe (v" & $sTag7z & ")...")
			If Not _Download($s7zrURL, $BIN_DIR & "\7zr.exe", $hProgBar, 85, 88) Then
				GUIDelete($hProg)
				MsgBox(16, $APP_TITLE, "Error: 7zr.exe could not be downloaded.")
				Return
			EndIf
		EndIf
		If Not FileExists($BIN_DIR & "\7za.exe") Then
			GUICtrlSetData($hProgInfo, "Downloading 7za.exe...")
			If Not _Download($s7zaURL, $BIN_DIR & "\7z_extra.7z", $hProgBar, 88, 91) Then
				GUIDelete($hProg)
				MsgBox(16, $APP_TITLE, "Error: 7z_extra.7z could not be downloaded.")
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
		GUICtrlSetData($hProgInfo, "Unpacking ffmpeg.exe...")
		_UnzipFFmpeg($sZip, $BIN_DIR)
		FileDelete($sZip)
		_ProgBar($hProgBar, 100)
		If Not FileExists($FFMPEG_EXE) Then
			GUIDelete($hProg)
			MsgBox(16, $APP_TITLE, "Error: ffmpeg.exe could not be unpacked.")
			Return
		EndIf
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
;  ZIP entpacken via Shell.Application (Wine-kompatibel)
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
	Local $sTmp = $sDestDir & "\ffmpeg_extracted", $s7zr = $sDestDir & "\7zr.exe", $s7za = $sDestDir & "\7za.exe", $sExtra = $sDestDir & "\7z_extra.7z"
	DirCreate($sTmp)
	If _IsWine() Then
		If Not FileExists($s7zr) Or FileGetSize($s7zr) < 100000 Then
			Local $s7zrURLFallback = _Get7zrURL()
			_Download($s7zrURLFallback, $s7zr)
			Do
				Sleep(100)
			Until FileExists($s7zr)
		EndIf
		If Not FileExists($s7za) Then
			If Not FileExists($sExtra) Then
				Local $aTagFB = StringRegExp(_Get7zrURL(), "/download/([^/]+)/", 1)
				Local $sTagFB = (Not @error And UBound($aTagFB) >= 1) ? $aTagFB[0] : "26.01"
				Local $sVerFB = StringReplace($sTagFB, ".", "")
				_Download("https://github.com/ip7z/7zip/releases/download/" & $sTagFB & "/7z" & $sVerFB & "-extra.7z", $sExtra)
				Do
					Sleep(100)
				Until FileExists($sExtra)
			EndIf
			Local $i7zaExit = RunWait('"' & $s7zr & '" e "' & $sExtra & '" 7za.exe -y', $sDestDir, @SW_HIDE)
			If $i7zaExit <> 0 Or Not FileExists($s7za) Then Return False
		EndIf
		If FileExists($sExtra) Then FileDelete($sExtra)
		If FileExists($s7za) Then
			Local $iExit = RunWait('"' & $s7za & '" x "' & $sZip & '" -o"' & $sTmp & '" -y', $sDestDir, @SW_HIDE)
			If $iExit <> 0 Then Return False
		Else
			Return False
		EndIf
	Else
		_UnZip($sZip, $sTmp)
		Sleep(2000)
	EndIf
	_FindAndCopyExe($sTmp, $sDestDir)
	DirRemove($sTmp, 1)
	Return FileExists($sDestDir & "\ffmpeg.exe")
EndFunc   ;==>_UnzipFFmpeg

; Prueft ob das Script unter Wine laeuft
Func _IsWine()
	RegRead("HKLM\Software\Wine", "Version")
	If @error = 0 Then Return True
	If StringLeft(@TempDir, 2) = "Z:" Or StringLeft(@TempDir, 2) = "z:" Then Return True
	If StringLeft(@ScriptDir, 2) = "Z:" Or StringLeft(@ScriptDir, 2) = "z:" Then Return True
	Return False
EndFunc   ;==>_IsWine

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
	GUICtrlSetData($hLabel, "  " & $sText)
	GUICtrlSetColor($hLabel, $iColor)
EndFunc   ;==>_SetStatus

; ============================================================
;  Update: yt-dlp.exe + ffmpeg.exe neu laden
; ============================================================
Func _UpdateTools($hStatus, $hProgBar, $hProgLabel, $hProgPct)
	_SetStatus($hStatus, "Checking for updates...", 0x4FC3F7)
	GUICtrlSetData($hProgLabel, "Starting update...")
	GUICtrlSetPos($hProgBar, 24, 364, 0, 12)
	GUICtrlSetBkColor($hProgBar, $CLR_ACCENT)
	GUICtrlSetData($hProgPct, "")

	GUICtrlSetData($hProgLabel, "Updating yt-dlp.exe...")
	Local $sURL1 = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
	Local $sTmp1 = $YTDLP_EXE & ".tmp"
	If _Download($sURL1, $sTmp1, $hProgBar, 0, 45, 24, 364, 512, 12) Then
		FileDelete($YTDLP_EXE)
		FileMove($sTmp1, $YTDLP_EXE)
		GUICtrlSetData($hProgLabel, "yt-dlp.exe updated!")
	Else
		FileDelete($sTmp1)
		_SetStatus($hStatus, "yt-dlp update failed!", 0xFF5252)
		Return
	EndIf

	GUICtrlSetData($hProgLabel, "Downloading ffmpeg... (~90 MB)")
	Local $sURL2 = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
	Local $sZip = $BIN_DIR & "\ffmpeg_update.zip"
	If _Download($sURL2, $sZip, $hProgBar, 45, 85, 24, 364, 512, 12) Then
		GUICtrlSetData($hProgLabel, "Unpacking ffmpeg.exe...")
		GUICtrlSetPos($hProgBar, 24, 364, Int(512 * 0.85), 12)
		FileDelete($BIN_DIR & "\ffmpeg.exe")
		FileDelete($BIN_DIR & "\ffprobe.exe")
		FileDelete($BIN_DIR & "\ffplay.exe")
		_UnzipFFmpeg($sZip, $BIN_DIR)
		FileDelete($sZip)
		If FileExists($FFMPEG_EXE) Then
			GUICtrlSetData($hProgLabel, "ffmpeg.exe updated!")
		Else
			_SetStatus($hStatus, "ffmpeg update failed - unpack error!", 0xFF5252)
			Return
		EndIf
	Else
		FileDelete($sZip)
		_SetStatus($hStatus, "ffmpeg download failed!", 0xFF5252)
		Return
	EndIf

	GUICtrlSetPos($hProgBar, 24, 364, 512, 12)
	GUICtrlSetBkColor($hProgBar, 0x00AA44)
	GUICtrlSetData($hProgPct, "Done!")
	GUICtrlSetData($hProgLabel, "All tools updated!")
	_SetStatus($hStatus, "Update complete!", 0x00AA44)
EndFunc   ;==>_UpdateTools

Func _Get7zrURL()
	Local $sAPI = "https://api.github.com/repos/ip7z/7zip/releases/latest"
	Local $sJSON = BinaryToString(InetRead($sAPI, 1))
	Local $aTag = StringRegExp($sJSON, '"tag_name"\s*:\s*"([^"]+)"', 1)
	If @error Or UBound($aTag) < 1 Then Return "https://github.com/ip7z/7zip/releases/download/26.01/7zr.exe"
	Local $sTag = $aTag[0]
	Local $sVer = StringReplace($sTag, ".", "")
	Return "https://github.com/ip7z/7zip/releases/download/" & $sTag & "/7zr.exe"
EndFunc   ;==>_Get7zrURL
