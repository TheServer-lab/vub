; ============================================================================
; Vub Build Tool - NSIS Installer Script
;
; Builds VubSetup.exe, which installs vub.exe (the Vub interpreter, built
; with PyInstaller) into Program Files, registers it on the system PATH,
; optionally associates .vub files with Python so double-clicking forge.vub
; opens the interactive "vub>" shell, creates Start Menu shortcuts, and adds
; an Add/Remove Programs entry with a proper uninstaller.
;
; Build with:  makensis installer.nsi
; ============================================================================

!define PRODUCT_NAME      "Vub"
!define PRODUCT_VERSION   "1.0.0"
!define PRODUCT_PUBLISHER "Vub Project"
!define PRODUCT_WEB_SITE  "https://example.com/vub"
!define PRODUCT_EXE       "vub.exe"
!define UNINST_KEY        "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define ENV_KEY           'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
!define VUB_FILE_PROGID   "VubFile"

SetCompressor /SOLID lzma

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "VubSetup.exe"
InstallDir "$PROGRAMFILES64\${PRODUCT_NAME}"
InstallDirRegKey HKLM "Software\${PRODUCT_NAME}" "InstallDir"
RequestExecutionLevel admin
ShowInstDetails show
ShowUnInstDetails show

; ----------------------------------------------------------------------------
; Modern UI + string-function helpers (both ship with NSIS, no plugins needed)
; ----------------------------------------------------------------------------
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "StrFunc.nsh"

${StrStr}
${StrRep}
${UnStrRep}

!define MUI_ABORTWARNING
!define MUI_ICON "vub.ico"
!define MUI_UNICON "vub.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.md"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "View README"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; ----------------------------------------------------------------------------
; Broadcast WM_SETTINGCHANGE so Explorer / new shells pick up PATH edits
; without requiring a reboot.
; ----------------------------------------------------------------------------
!define /ifndef WM_SETTINGCHANGE 0x001A
!define /ifndef SMTO_ABORTIFHUNG 0x0002

Function RefreshEnvironment
  System::Call 'user32::SendMessageTimeoutA(i 0xffff, i ${WM_SETTINGCHANGE}, i 0, t "Environment", i ${SMTO_ABORTIFHUNG}, i 5000, *i .r0)'
FunctionEnd

; ----------------------------------------------------------------------------
; Main install section
; ----------------------------------------------------------------------------
Section "Vub CLI (required)" SEC_MAIN
  SectionIn RO
  SetOutPath "$INSTDIR"

  File "${PRODUCT_EXE}"
  File "README.md"
  File "LICENSE.txt"
  File "vub.ico"
  File "forge.vub"

  WriteRegStr HKLM "Software\${PRODUCT_NAME}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKLM "${UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "${UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr HKLM "${UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\${PRODUCT_EXE}"
  WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoRepair" 1

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  CreateShortcut "$SMPROGRAMS\${PRODUCT_NAME}\Vub Command Prompt.lnk" \
    "$SYSDIR\cmd.exe" '/k "cd /d $INSTDIR"' "$INSTDIR\${PRODUCT_EXE}"
  CreateShortcut "$SMPROGRAMS\${PRODUCT_NAME}\Vub README.lnk" "$INSTDIR\README.md" "" "$INSTDIR\vub.ico"
  CreateShortcut "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall ${PRODUCT_NAME}.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\vub.ico"
SectionEnd

; ----------------------------------------------------------------------------
; Optional: add install directory to the system PATH
; ----------------------------------------------------------------------------
Section "Add to system PATH" SEC_PATH
  ReadRegStr $0 ${ENV_KEY} "Path"

  ${StrStr} $1 "$0;" "$INSTDIR;"
  ${If} $1 == ""
    ${If} $0 == ""
      StrCpy $0 "$INSTDIR"
    ${Else}
      StrCpy $0 "$0;$INSTDIR"
    ${EndIf}
    WriteRegExpandStr ${ENV_KEY} "Path" "$0"
    Call RefreshEnvironment
  ${EndIf}
SectionEnd

; ----------------------------------------------------------------------------
; Optional: register .vub files so that double-clicking forge.vub opens a
; terminal with the interactive "vub>" shell (via Python, if present).
; ----------------------------------------------------------------------------
Section "Associate .vub files" SEC_ASSOC
  ; Locate python.exe: App Paths key, then PythonCore InstallPath (per-user or per-machine).
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\App Paths\python.exe" ""
  ${If} $0 == ""
    ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\App Paths\python.exe" ""
  ${EndIf}
  ${If} $0 == ""
    ReadRegStr $1 HKCU "Software\Python\PythonCore\CurrentVersion" ""
    ${If} $1 == ""
      ReadRegStr $1 HKLM "Software\Python\PythonCore\CurrentVersion" ""
    ${EndIf}
    ${If} $1 != ""
      ReadRegStr $0 HKCU "Software\Python\PythonCore\$1\InstallPath" ""
      ${If} $0 == ""
        ReadRegStr $0 HKLM "Software\Python\PythonCore\$1\InstallPath" ""
      ${EndIf}
      ${If} $0 != ""
        StrCpy $0 "$0python.exe"
      ${EndIf}
    ${EndIf}
  ${EndIf}
  ${If} $0 == ""
    MessageBox MB_ICONINFORMATION|MB_OK "Python was not found. .vub files will not be associated, so double-clicking a .vub file won't open the vub> shell. Install Python 3 and re-run this installer to enable it."
  ${Else}
    WriteRegStr HKCU "Software\Classes\.vub" "" "${VUB_FILE_PROGID}"
    WriteRegStr HKCU "Software\Classes\${VUB_FILE_PROGID}\shell\open\command" "" '"$0" "%1" %*'
  ${EndIf}
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_MAIN} "The vub.exe interpreter, README, and license. Required."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_PATH} "Lets you run 'vub' from any Command Prompt or PowerShell window without typing the full path."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_ASSOC} "Associates .vub files with Python so double-clicking forge.vub opens the interactive 'vub>' shell."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ----------------------------------------------------------------------------
; Uninstaller
; ----------------------------------------------------------------------------
Section "Uninstall"
  Delete "$INSTDIR\${PRODUCT_EXE}"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\vub.ico"
  Delete "$INSTDIR\forge.vub"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"

  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Vub Command Prompt.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Vub README.lnk"
  Delete "$SMPROGRAMS\${PRODUCT_NAME}\Uninstall ${PRODUCT_NAME}.lnk"
  RMDir "$SMPROGRAMS\${PRODUCT_NAME}"

  ; Remove the .vub file association, if present
  DeleteRegKey HKCU "Software\Classes\${VUB_FILE_PROGID}"
  DeleteRegKey HKCU "Software\Classes\.vub"

  DeleteRegKey HKLM "${UNINST_KEY}"
  DeleteRegKey HKLM "Software\${PRODUCT_NAME}"

  ; Remove "$INSTDIR;" from PATH, if present
  ReadRegStr $0 ${ENV_KEY} "Path"
  ${UnStrRep} $0 "$0" "$INSTDIR;" ""
  ${UnStrRep} $0 "$0" "$INSTDIR" ""
  WriteRegExpandStr ${ENV_KEY} "Path" "$0"
  Call un.RefreshEnvironment
SectionEnd

Function un.RefreshEnvironment
  System::Call 'user32::SendMessageTimeoutA(i 0xffff, i ${WM_SETTINGCHANGE}, i 0, t "Environment", i ${SMTO_ABORTIFHUNG}, i 5000, *i .r0)'
FunctionEnd
