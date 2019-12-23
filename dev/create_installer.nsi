RequestExecutionLevel admin

!include LogicLib.nsh
!include MUI2.nsh
!include nsProcess.nsh

var perlRootDir 
var perlRootDirSet

!define PRODUCT_NAME "berrybrew"
!define PRODUCT_VERSION "1.30"
!define PRODUCT_PUBLISHER "Steve Bertrand"
!define PRODUCT_WEB_SITE "https://github.com/stevieb9/berrybrew"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\berrybrew.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define APP_REGKEY "Software\berrybrew"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

!define MUI_ABORTWARNING
!define MUI_ICON "..\inc\berrybrew.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY

; Perl root_path directory
!define MUI_PAGE_HEADER_SUBTEXT "Directory to store the Perl instances"
!define MUI_DIRECTORYPAGE_TEXT_TOP "Choose a directory to store the Perl instances"
!define MUI_DIRECTORYPAGE_VARIABLE $perlRootDir
!define MUI_PAGE_CUSTOMFUNCTION_PRE perlRootPathSelection
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_FINISHPAGE_RUN
!define MUI_PAGE_CUSTOMFUNCTION_SHOW ModifyRunCheckbox
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchFinish"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "..\download\berrybrewInstaller.exe"
InstallDir "$PROGRAMFILES\berrybrew\"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

Section "-MainSection" SEC_MAIN
  SetOverwrite try
  SetOutPath "$PROGRAMFILES\berrybrew\bin"
  File "..\bin\berrybrew-refresh.bat"
  File "..\bin\bbapi.dll"
  File "..\bin\berrybrew.exe"
  File "..\bin\bb.exe"
  File "..\bin\berrybrew-ui.exe"
  File "..\bin\ICSharpCode.SharpZipLib.dll"
  File "..\bin\Newtonsoft.Json.dll"
  File "..\bin\env.exe"
  File "..\bin\libiconv2.dll"

  SetOutPath "$PROGRAMFILES\berrybrew"
  File "..\Changes"
  File "..\Changes.md"
  File "..\CONTRIBUTING.md"
  SetOutPath "$PROGRAMFILES\berrybrew\data"
  File "..\data\config.json"
  File "..\data\messages.json"
  File "..\data\perls.json"
  SetOutPath "$PROGRAMFILES\berrybrew\doc"
  File "..\doc\Berrybrew API.md"
  File "..\doc\berrybrew.md"
  File "..\doc\Compile Your Own.md"
  File "..\doc\Configuration.md"
  File "..\doc\Create a Development Build.md"
  File "..\doc\Create a Release.md"
  File "..\doc\Unit Testing.md"
  SetOutPath "$PROGRAMFILES\berrybrew\inc"
  File "..\inc\berrybrew.ico"
  SetOutPath "$PROGRAMFILES\berrybrew"
  File "..\LICENSE"
  SetOutPath "$PROGRAMFILES\berrybrew\src"
  File "..\src\bbconsole.cs"
  File "..\src\berrybrew.cs"
SectionEnd

Section "Perl 5.30.1_64" SEC_INSTALL_NEWEST_PERL
SectionEnd

Section "Run UI at startup" SEC_START_UI
SectionEnd

Section "Manage .pl file association" SEC_FILE_ASSOC
SectionEnd

Section -AdditionalIcons
  SetOutPath $INSTDIR
  WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
  CreateShortCut "$SMPROGRAMS\berrybrew\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
  CreateShortCut "$SMPROGRAMS\berrybrew\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  
  ${If} ${SectionIsSelected} ${SEC_START_UI}
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "BerrybrewUI" "$INSTDIR\bin\berrybrew-ui.exe"
  ${EndIf}
      
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$PROGRAMFILES\berrybrew\bin\berrybrew.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$PROGRAMFILES\berrybrew\bin\berrybrew.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

Function perlRootPathSelection
   ; check if the root path for Perls is already set
   ClearErrors
   ReadRegStr $0 HKLM "${APP_REGKEY}" "root_dir"
   ${If} ${Errors}
     StrCpy $perlRootDirSet "0"
   ${Else}
       StrCpy $perlRootDir $0
       StrCpy $perlRootDirSet "1"
       Abort
   ${EndIf} 
FunctionEnd     

Function ModifyRunCheckbox
    SendMessage $mui.FinishPage.Run ${BM_SETCHECK} ${BST_CHECKED} 0
    ShowWindow $mui.FinishPage.Run 0
FunctionEnd

Function LaunchFinish
  SetOutPath $INSTDIR
   
  nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" config'
  nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" register_orphans'

  ${If} ${SectionIsSelected} ${SEC_INSTALL_NEWEST_PERL}
    ${If} ${FileExists} "C:\berrybrew\5.30.1_64\perl\bin\perl.exe"
      MessageBox MB_OK "Perl 5.30.1_64 is already installed, we'll switch to it"
    ${Else}
      ExecWait '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" install 5.30.1_64'
    ${EndIf}
    nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" switch 5.30.1_64'
  ${EndIf}

  ${If} ${SectionIsSelected} ${SEC_FILE_ASSOC}
    nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" associate set'
    nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" associate'
  ${EndIf}   
FunctionEnd

Function .oninstsuccess
  nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew" options-update'
  Exec '"$INSTDIR\bin\berrybrew-ui.exe"'
  
   ; set the root_path Perl directory location

  ${If} $perlRootDirSet == "0"
    ClearErrors
    WriteRegStr HKLM "${APP_REGKEY}" "root_dir" $perlRootDir
    WriteRegStr HKLM "${APP_REGKEY}" "temp_dir" "$perlRootDir\temp"
    ${If} ${Errors}
      MessageBox MB_OK "Error writing registry"
    ${EndIf}      
  ${EndIf}  
 
FunctionEnd

Function un.StopUI
    ${nsProcess::FindProcess} "berrybrew-ui.exe" $R0
    ${If} $R0 == 0
        DetailPrint "berrybrew-ui.exe is running. Closing it down"
        ${nsProcess::KillProcess} "berrybrew-ui.exe" $R0
        DetailPrint "Waiting for berrybrew-ui.exe to close"
        Sleep 2000  
    ${Else}
        DetailPrint "berrybrew-ui.exe was not found to be running"        
    ${EndIf}    
    ${nsProcess::Unload}
FunctionEnd

Function StopUI
    ${nsProcess::FindProcess} "berrybrew-ui.exe" $R0
    ${If} $R0 == 0
        DetailPrint "berrybrew-ui.exe is running. Closing it down"
        ${nsProcess::KillProcess} "berrybrew-ui.exe" $R0
        DetailPrint "Waiting for berrybrew-ui.exe to close"
        Sleep 2000  
    ${Else}
        DetailPrint "berrybrew-ui.exe was not found to be running"        
    ${EndIf}    
    ${nsProcess::Unload}
FunctionEnd

Function .onInit
  SetRegView 64

  Call StopUI
      
  StrCpy $perlRootDir "C:\berrybrew"
  StrCpy $perlRootDirSet "0"

  StrCpy $InstDir "$PROGRAMFILES\berrybrew\"

  ; check for previously installed versions
   
  IfFileExists "$INSTDIR\bin\berrybrew.exe" file_found file_not_found

    file_found:
   
      MessageBox MB_ICONQUESTION|MB_YESNO "This will upgrade your existing berrybrew install. Continue?" IDYES true IDNO false
      false: 
        Abort
      true:
        nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew" off'
        nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew" unconfig' 

        goto end_find_file
      
    file_not_found:
  
      nsExec::ExecToStack '"berrybrew" version'
      Pop $1  

      ${If} $1 == 0
        MessageBox MB_ICONQUESTION|MB_YESNO "You have a previous version of berrybrew. Can we try to disable it?" IDYES yep IDNO nope
        nope:
          Abort
        yep:
          nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew" off'
          nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew" unconfig'
          MessageBox MB_ICONEXCLAMATION "If you need to use your previous version, run 'berrybrew off', and re-run 'config' and 'switch' on the old version."
      ${EndIf}
    
    end_find_file:      
FunctionEnd

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  SetRegView 64
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
  
  Call un.StopUI
FunctionEnd

Section Uninstall
  SetOutPath $INSTDIR
  nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew" associate unset'
  nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" off'
  nsExec::Exec '"$SYSDIR\cmd.exe" /C if 1==1 "$INSTDIR\bin\berrybrew.exe" unconfig'
  Delete "$INSTDIR\${PRODUCT_NAME}.url"
  Delete "$INSTDIR\uninst.exe"
  Delete "$PROGRAMFILES\berrybrew\src\berrybrew.cs"
  Delete "$PROGRAMFILES\berrybrew\src\bbconsole.cs"
  Delete "$PROGRAMFILES\berrybrew\LICENSE"
  Delete "$PROGRAMFILES\berrybrew\inc\berrybrew.ico"
  Delete "$PROGRAMFILES\berrybrew\doc\Unit Testing.md"
  Delete "$PROGRAMFILES\berrybrew\doc\Create a Release.md"
  Delete "$PROGRAMFILES\berrybrew\doc\Create a Development Build.md"
  Delete "$PROGRAMFILES\berrybrew\doc\Configuration.md"
  Delete "$PROGRAMFILES\berrybrew\doc\Compile Your Own.md"
  Delete "$PROGRAMFILES\berrybrew\doc\berrybrew.md"
  Delete "$PROGRAMFILES\berrybrew\doc\Berrybrew API.md"
  Delete "$PROGRAMFILES\berrybrew\data\perls.json"
  Delete "$PROGRAMFILES\berrybrew\data\perls_custom.json"
  Delete "$PROGRAMFILES\berrybrew\data\perls_virtual.json"
  Delete "$PROGRAMFILES\berrybrew\data\messages.json"
  Delete "$PROGRAMFILES\berrybrew\data\config.json"
  Delete "$PROGRAMFILES\berrybrew\CONTRIBUTING.md"
  Delete "$PROGRAMFILES\berrybrew\Changes.md"
  Delete "$PROGRAMFILES\berrybrew\Changes"
  Delete "$PROGRAMFILES\berrybrew\bin\berrybrew-refresh.bat"
  Delete "$PROGRAMFILES\berrybrew\bin\Newtonsoft.Json.dll"
  Delete "$PROGRAMFILES\berrybrew\bin\ICSharpCode.SharpZipLib.dll"
  Delete "$PROGRAMFILES\berrybrew\bin\berrybrew.exe"
  Delete "$PROGRAMFILES\berrybrew\bin\bb.exe"
  Delete "$PROGRAMFILES\berrybrew\bin\berrybrew-ui.exe"
  Delete "$PROGRAMFILES\berrybrew\bin\bbapi.dll"
  Delete "$PROGRAMFILES\berrybrew\bin\env.exe"
  Delete "$PROGRAMFILES\berrybrew\bin\libintl3.dll"
  Delete "$PROGRAMFILES\berrybrew\bin\libiconv2.dll"
  Delete "$PROGRAMFILES\berrybrew\bin\uninst.exe"
  Delete "$PROGRAMFILES\berrybrew\bin\berrybrew.lnk"
  Delete "$PROGRAMFILES\berrybrew\bin\berrybrew.url"
  Delete "$PROGRAMFILES\berrybrew\bin\berrybrew"

  Delete "$SMPROGRAMS\berrybrew\Uninstall.lnk"
  Delete "$SMPROGRAMS\berrybrew\Website.lnk"
  Delete "$DESKTOP\berrybrew.lnk"
  Delete "$SMPROGRAMS\berrybrew\berrybrew.lnk"

  RMDir "$SMPROGRAMS\berrybrew"
  RMDir "$PROGRAMFILES\berrybrew\t\data"
  RMDir "$PROGRAMFILES\berrybrew\t"
  RMDir "$PROGRAMFILES\berrybrew\src"
  RMDir "$PROGRAMFILES\berrybrew\inc"
  RMDir "$PROGRAMFILES\berrybrew\download"
  RMDir "$PROGRAMFILES\berrybrew\doc"
  RMDir "$PROGRAMFILES\berrybrew\dev\data"
  RMDir "$PROGRAMFILES\berrybrew\dev"
  RMDir "$PROGRAMFILES\berrybrew\data"
  RMDir "$PROGRAMFILES\berrybrew\bin"
  RMDir "$PROGRAMFILES\berrybrew"

  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "BerrybrewUI"
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKLM "${APP_REGKEY}"
  SetAutoClose true
SectionEnd
