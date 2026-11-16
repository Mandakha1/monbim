; MonBIM Windows installer (NSIS 3, Unicode). Per-user: no administrator rights needed.
;
;   makensis -DVERSION=0.12.0 -DYEAR=2026 -DBINDIR=<folder with monbim.exe and monbim-cli.exe> \
;            -DOUTFILE=<dist>/monbim-2026-<ver>-windows-x64-setup.exe packaging/monbim/windows/monbim.nsi
;
; Installs to %LOCALAPPDATA%\Programs\MonBIM, adds Start menu entries ("MonBIM 2026" and "MonBIM 2026 (AI)", which opens the
; window's control port for an agent) and, if ticked, a desktop shortcut, registers an uninstaller under "Apps & features" and
; the id Windows shows MonBIM's notifications under, and writes "AI-connect.txt" with the exact commands that connect Claude,
; ChatGPT or Codex to this copy of monbim-cli.exe.
; Silent install: monbim-<year>-<ver>-windows-x64-setup.exe /S   (add /DESKTOP=1 for the desktop shortcut)

Unicode true
SetCompressor /SOLID lzma
RequestExecutionLevel user

!ifndef VERSION
  !define VERSION "0.0.0"
!endif
!ifndef BINDIR
  !error "pass -DBINDIR=<folder with monbim.exe and monbim-cli.exe>"
!endif
!ifndef YEAR
  !define YEAR "2026"
!endif
!ifndef OUTFILE
  !define OUTFILE "monbim-${YEAR}-${VERSION}-windows-x64-setup.exe"
!endif
; makensis works in the script's folder, so ROOT (the repository) is best passed as an absolute path.
; Path separator for compile-time paths: makensis on Windows needs "\" in File patterns, makensis on
; macOS/Linux needs "/".
!ifdef NSIS_WIN32_MAKENSIS
  !define SEP "\"
!else
  !define SEP "/"
!endif
!ifndef ROOT
  !define ROOT "${__FILEDIR__}${SEP}..${SEP}..${SEP}.."
!endif
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\MonBIM"
; The id Windows notifications (news, courses, offers) are shown under; the app uses the same one (brand::AUMID).
!define AUMID "MonHydro.MonBIM"
!define FULLNAME "MonBIM ${YEAR}"
; The control port the "(AI)" shortcut opens and AI-connect.txt connects to: MonCad's is 7979, Mon3D's 7878, so all three can
; run side by side.
!define AIPORT "7676"

Name "${FULLNAME}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Programs\MonBIM"
InstallDirRegKey HKCU "Software\MonBIM" "InstallDir"
BrandingText "${FULLNAME} (${VERSION})"
VIProductVersion "0.0.0.0"
VIAddVersionKey /LANG=1033 "ProductName" "${FULLNAME}"
VIAddVersionKey /LANG=1033 "FileDescription" "${FULLNAME} setup"
VIAddVersionKey /LANG=1033 "ProductVersion" "${VERSION}"
VIAddVersionKey /LANG=1033 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1033 "LegalCopyright" "MonBIM, based on BIMCraft by IPedrax and the BIMCraft contributors. Apache-2.0 (MIT OR Apache-2.0 without the Revit reader)."

!include "MUI2.nsh"
!include "FileFunc.nsh"

!define MUI_ICON "${ROOT}${SEP}assets${SEP}app-icon${SEP}bimcraft.ico"
!define MUI_UNICON "${ROOT}${SEP}assets${SEP}app-icon${SEP}bimcraft.ico"
!define MUI_ABORTWARNING
!define MUI_LANGDLL_ALLLANGUAGES
!define MUI_FINISHPAGE_RUN "$INSTDIR\monbim.exe"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\AI-connect.txt"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "$(ShowAiText)"

!insertmacro MUI_PAGE_WELCOME
; The default build reads Revit files with code that is Apache-2.0 only (docs/rvt-provenance.md): the package is Apache-2.0.
!insertmacro MUI_PAGE_LICENSE "${ROOT}${SEP}LICENSE-APACHE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Mongolian"
!insertmacro MUI_LANGUAGE "English"

LangString SecApp ${LANG_MONGOLIAN} "${FULLNAME} програм"
LangString SecApp ${LANG_ENGLISH} "${FULLNAME} application"
LangString SecDesktop ${LANG_MONGOLIAN} "Ширээний компьютер дээр товчлол"
LangString SecDesktop ${LANG_ENGLISH} "Desktop shortcut"
LangString ShowAiText ${LANG_MONGOLIAN} "Claude / ChatGPT-тэй холбох заавар харах"
LangString ShowAiText ${LANG_ENGLISH} "Show how to connect Claude / ChatGPT"

Function .onInit
  ; Ask for the installer language (Mongolian or English). A silent install never asks: the jump
  ; goes to a label because MUI_LANGDLL_DISPLAY expands to many instructions (IfSilent +2 would
  ; skip only the first, and /S would wait on the dialog forever).
  IfSilent skip_language
  !insertmacro MUI_LANGDLL_DISPLAY
  skip_language:
FunctionEnd

Section "!$(SecApp)" SecMain
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "${BINDIR}${SEP}monbim.exe"
  File "${BINDIR}${SEP}monbim-cli.exe"
  File /oname=monbim.ico "${ROOT}${SEP}assets${SEP}app-icon${SEP}bimcraft.ico"
  File "${ROOT}${SEP}LICENSE-APACHE"
  File "${ROOT}${SEP}LICENSE-MIT"
  File "${ROOT}${SEP}NOTICE"
  File "${ROOT}${SEP}README.md"
  ; The fonts' licence, where NOTICE says it is (the OFL asks for it with every copy of the fonts monbim.exe holds).
  SetOutPath "$INSTDIR\fonts\ibm-plex-sans"
  File "${ROOT}${SEP}assets${SEP}fonts${SEP}ibm-plex-sans${SEP}OFL.txt"
  SetOutPath "$INSTDIR\fonts\ibm-plex-mono"
  File "${ROOT}${SEP}assets${SEP}fonts${SEP}ibm-plex-mono${SEP}OFL.txt"
  SetOutPath "$INSTDIR"

  ; Ready-to-paste commands with this install's real path. With --connect the agent works on the project open in the window
  ; started from "MonBIM (AI)"; plain `mcp` is a project of the agent's own, with no window. UTF-16 with a byte order mark,
  ; not FileWrite's ANSI code page: the Mongolian line and a Cyrillic user name in the path come out as they are.
  FileOpen $0 "$INSTDIR\AI-connect.txt" w
  FileWriteUTF16LE /BOM $0 "${FULLNAME} - AI connection / AI холболт$\r$\n$\r$\n"
  FileWriteUTF16LE $0 "1. Start ${FULLNAME} (AI) from the Start menu / Start цэснээс ${FULLNAME} (AI)-г нээнэ.$\r$\n$\r$\n"
  FileWriteUTF16LE $0 "2. Claude Code (terminal):$\r$\n"
  FileWriteUTF16LE $0 '  claude mcp add monbim -- "$INSTDIR\monbim-cli.exe" mcp --connect ${AIPORT}$\r$\n$\r$\n'
  FileWriteUTF16LE $0 "Claude Desktop (claude_desktop_config.json):$\r$\n"
  FileWriteUTF16LE $0 '  { "mcpServers": { "monbim": { "command": "$INSTDIR\monbim-cli.exe", "args": ["mcp", "--connect", "${AIPORT}"] } } }$\r$\n'
  FileWriteUTF16LE $0 "  (JSON: write every \ in the path as \\)$\r$\n$\r$\n"
  FileWriteUTF16LE $0 "ChatGPT desktop app: Settings > MCP servers > Add server > STDIO$\r$\n"
  FileWriteUTF16LE $0 '  command: "$INSTDIR\monbim-cli.exe"   arguments: mcp --connect ${AIPORT}$\r$\n$\r$\n'
  FileWriteUTF16LE $0 "Codex CLI:$\r$\n"
  FileWriteUTF16LE $0 '  codex mcp add monbim -- "$INSTDIR\monbim-cli.exe" mcp --connect ${AIPORT}$\r$\n$\r$\n'
  FileWriteUTF16LE $0 "Without a window (headless, the AI models and saves files): replace the arguments with just: mcp$\r$\n"
  FileWriteUTF16LE $0 "Read only (the AI may look, never change): add --read-only after mcp$\r$\n"
  FileClose $0

  ; Shortcuts carry the year; an older year's shortcuts are replaced.
  CreateDirectory "$SMPROGRAMS\MonBIM"
  Delete "$SMPROGRAMS\MonBIM\*.lnk"
  CreateShortcut "$SMPROGRAMS\MonBIM\${FULLNAME}.lnk" "$INSTDIR\monbim.exe" "" "$INSTDIR\monbim.exe" 0
  CreateShortcut "$SMPROGRAMS\MonBIM\${FULLNAME} (AI).lnk" "$INSTDIR\monbim.exe" "--control ${AIPORT}" "$INSTDIR\monbim.exe" 0
  CreateShortcut "$SMPROGRAMS\MonBIM\Uninstall ${FULLNAME}.lnk" "$INSTDIR\uninstall.exe"

  ; Windows notifications from MonBIM show its name and icon (an unpackaged app registers its id).
  WriteRegStr HKCU "Software\Classes\AppUserModelId\${AUMID}" "DisplayName" "${FULLNAME}"
  WriteRegStr HKCU "Software\Classes\AppUserModelId\${AUMID}" "IconUri" "$INSTDIR\monbim.ico"

  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\MonBIM" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayName" "${FULLNAME}"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNINST_KEY}" "Publisher" "MonBIM"
  WriteRegStr HKCU "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\monbim.exe"
  WriteRegStr HKCU "${UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINST_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKCU "${UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  WriteRegDWORD HKCU "${UNINST_KEY}" "EstimatedSize" "$0"
SectionEnd

Section /o "$(SecDesktop)" SecDesk
  CreateShortcut "$DESKTOP\${FULLNAME}.lnk" "$INSTDIR\monbim.exe" "" "$INSTDIR\monbim.exe" 0
SectionEnd

Function .onInstSuccess
  ; /DESKTOP=1 on a silent install adds the desktop shortcut too.
  ${GetParameters} $0
  ${GetOptions} $0 "/DESKTOP=" $1
  StrCmp $1 "1" 0 +2
  CreateShortcut "$DESKTOP\${FULLNAME}.lnk" "$INSTDIR\monbim.exe" "" "$INSTDIR\monbim.exe" 0
FunctionEnd

Section "Uninstall"
  Delete "$INSTDIR\monbim.exe"
  Delete "$INSTDIR\monbim-cli.exe"
  Delete "$INSTDIR\monbim.ico"
  Delete "$INSTDIR\LICENSE-APACHE"
  Delete "$INSTDIR\LICENSE-MIT"
  Delete "$INSTDIR\NOTICE"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\fonts\ibm-plex-sans\OFL.txt"
  Delete "$INSTDIR\fonts\ibm-plex-mono\OFL.txt"
  RMDir "$INSTDIR\fonts\ibm-plex-sans"
  RMDir "$INSTDIR\fonts\ibm-plex-mono"
  RMDir "$INSTDIR\fonts"
  Delete "$INSTDIR\AI-connect.txt"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\MonBIM\*.lnk"
  RMDir "$SMPROGRAMS\MonBIM"
  Delete "$DESKTOP\MonBIM *.lnk"
  DeleteRegKey HKCU "Software\Classes\AppUserModelId\${AUMID}"
  DeleteRegKey HKCU "${UNINST_KEY}"
  DeleteRegKey HKCU "Software\MonBIM"
  ; Projects and the settings folder (%APPDATA%\MonBIM) are the user's and stay.
SectionEnd
