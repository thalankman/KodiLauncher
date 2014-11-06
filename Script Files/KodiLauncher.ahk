/*
 * * * Compile_AHK SETTINGS BEGIN * * *

[AHK2EXE]
Exe_File=%In_Dir%\KodiLauncher.exe
Created_Date=1
[VERSION]
Set_Version_Info=1
Company_Name=baijuxavior@gmail.com
File_Description=KodiLauncher
File_Version=1.0.0.0
Inc_File_Version=0
Internal_Name=KodiLauncher
Legal_Copyright=C@P Baiju Xavior
Original_Filename=KodiLauncher
Product_Name=KodiLauncher
Product_Version=1.0.0.0
[ICONS]
Icon_1=%In_Dir%\KodiLauncher.ico
Icon_2=%In_Dir%\KodiLauncher.ico

* * * Compile_AHK SETTINGS END * * *
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Recommended for catching common errors.
#SingleInstance ignore ; create only one running instance

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

DllCall("CreateMutex", "uint", 0, "int", false, "str", "kodi_launcher_mutex") ; create a mutex to find whether the application is already running while installation.

ProgFiles32() ;get 32 bit program files folder
{
    EnvGet, ProgFiles32, ProgramFiles(x86)
    if ProgFiles32 = ; Probably not on a 64-bit system.
    EnvGet, ProgFiles32, ProgramFiles
    Return %ProgFiles32%
}


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		 	GLOBAL VARIABLES DECLARATION AND DEFAULT VALUES 	<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


objWMIService := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\" A_ComputerName "\root\cimv2")
For objOperatingSystem in objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
Global OSVersion := 	objOperatingSystem.Version
global AppVersion = 1.0

Global ProgFiles := ProgFiles32() ;Program files path
global FocusDelay := GetSettings("FocusDelay", 10000)
global FocusOnce := GetSettings("FocusOnce", 0)
global DisableFocusTemporarily = 0
global DisableFocusPermanently := GetSettings("DisableFocusPermanently", 0)
global FocussedOnce = 0
global FocusCount = 0

global CloseKodiOnSleep := GetSettings("CloseKodiOnSleep", 0)
global ForceCloseKodi := GetSettings("ForceCloseKodi", 0)
global StartExplorer := GetSettings("StartExplorer", 1)
global StartMetroUI := GetSettings("StartMetroUI", 1)
global WinKeySent = 0
global ShowCustomShutdownMenu := GetSettings("ShowCustomShutdownMenu", 0)
global ShutdownAction := GetSettings("ShutdownAction", "u")
global ShutdownButtonClicked := GetSettings("ShutdownButtonClicked", 0)

global Suspending = 0
global StartupDelay := GetSettings("StartupDelay", 0)
global StartKodiOnWinLogon := GetSettings("StartKodiOnWinLogon", 1)
global StartKodiOnWinResume := GetSettings("StartKodiOnWinResume", 0)
global StartKodiInPortableMode := GetSettings("StartKodiInPortableMode", 0)
global BreakFocus = 0 ; break focus while setting KodiLauncher settings


global KodiPath := GetSettings("Kodi_Path", ProgFiles . "\Kodi\Kodi.exe")
global XBMConiMONPath := GetSettings("XBMConiMON_Path", "")
global iMONPath := GetSettings("iMON_Path", ProgFiles . "\SoundGraph\iMON\iMON.exe")

global ExternalPlayerRunning = 0
global ExternalPlayer1 := GetSettings("ExternalPlayer1_Path", "")
global ExternalPlayer2 := GetSettings("ExternalPlayer2_Path", "")
global ExternalPlayer3 := GetSettings("ExternalPlayer3_Path", "")
global ExternalPlayer4 := GetSettings("ExternalPlayer4_Path", "")
global ExternalPlayerName = ""
global FocusExternalPlayer := GetSettings("FocusExternalPlayer", 0)


Global App1 := GetSettings("App1_Path", "")
Global App2 := GetSettings("App2_Path", "")
Global App3 := GetSettings("App3_Path", "")
global StartApps1 := GetSettings("StartApps1", 0)
global PreventFocusApps1 := GetSettings("PreventFocusApps1", 0)

Global App4 := GetSettings("App4_Path", "")
Global App5 := GetSettings("App5_Path", "")
Global App6 := GetSettings("App6_Path", "")
global StartApps2 := GetSettings("StartApps2", 0)
global PreventFocusApps2 := GetSettings("PreventFocusApps2", 0)

Global App7 := GetSettings("App7_Path", "")
Global App8 := GetSettings("App8_Path", "")
Global App9 := GetSettings("App9_Path", "")
global StartApps3 := GetSettings("StartApps3", 0)
global PreventFocusApps3 := GetSettings("PreventFocusApps3", 0)

global ReloadKodiLauncher := GetSettings("ReloadKodiLauncher", 0)
SaveSettings("ReloadKodiLauncher", 0)
SaveSettings("RestartKodi", 0)

global ShellName
RegRead, ShellName, HKCU, Software\Microsoft\Windows NT\CurrentVersion\Winlogon, Shell
	SplitPath, ShellName, ShellName ;get file name only
		;MsgBox %ShellName%
	


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>	 CREATE MENU ITEMS 		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

fdelay := FocusDelay // 1000 ; variable to show menu name with delay
sdelay := StartupDelay // 1000
IfExist, %A_WorkingDir%\KodiLauncher.ico
Menu, Tray, Icon, %A_WorkingDir%\KodiLauncher.ico ; create tray icon.
Menu, Tray, Tip, KodiLauncher V%AppVersion% `nRight click to view menu
Menu, Tray, add, Start Kodi [Win+Alt+Enter], MenuStartKodiHandler
Menu, Tray, add, Force Close Kodi Now, MenuForceCloseKodiNow
Menu, Tray, add ;add separator
Menu, Tray, add, Start Explorer [Win+E], MenuStartExplorer
Menu, Tray, add, Show Settings GUI [Win+S], MenuShowSettingsGUI
Menu, Tray, add ;add separator
Menu, KodiStartSubMenu, add, Start Kodi When Windows Starts, MenuStartKodiAtWindowsLogonHandler
Menu, KodiStartSubMenu, add, Start Kodi When Windows Resumes from Sleep, MenuStartKodiAtWindowsResumeHandler
Menu, KodiStartSubMenu, add, Start Kodi in Portable Mode, MenuStartKodiInPortableModeHandler
Menu, KodiStartSubMenu, add,
Menu, KodiStartSubMenu, add, Change Startup Delay [%sdelay% sec], MenuSetStartupDelayHandler
Menu, KodiStartSubMenu, UnCheck, Start Kodi When Windows Starts
Menu, KodiStartSubMenu, UnCheck, Start Kodi When Windows Resumes from Sleep
Menu, KodiStartSubMenu, UnCheck, Start Kodi in Portable Mode
Menu, Tray, add, Kodi Startup Settings, :KodiStartSubMenu

Menu, FocusSubMenu, add, Change Focus Delay [%fdelay% sec], MenuSetFocusDelayHandler
Menu, FocusSubMenu, add,
Menu, FocusSubMenu, add, Disable Focus Permanently, MenuDisableFocusPermanentlyHandler
Menu, FocusSubMenu, UnCheck, Disable Focus Permanently
Menu, FocusSubMenu, add, Disable Focus Temporarily [Win+F9], MenuDisableFocusHandler
Menu, FocusSubMenu, UnCheck, Disable Focus Temporarily [Win+F9]
Menu, FocusSubMenu, add, Check Focus Only Once, MenuCheckFocusOnceHandler
Menu, FocusSubMenu, UnCheck, Check Focus Only Once
Menu, Tray, add, Kodi Focus Settings, :FocusSubMenu

if (ShowCustomShutdownMenu = 1)
	{	global currentshutdownaction := "Shutdown"
		If (ShutdownAction = "u")
			currentshutdownaction := "Shutdown"
		If (ShutdownAction = "h")
			currentshutdownaction := "Hibernate"
		If (ShutdownAction = "s")
			currentshutdownaction := "Sleep"
		Menu, KodiExitSubMenu, add, Set Shutdown Button Action [for custom shutdown menu only] - %currentshutdownaction%, MenuSetShutdownActionHandler
		
		Menu, KodiExitSubMenu, add, Force Close Kodi instead of Normal Close [for custom shutdown menu only], MenuForceCloseKodiHandler
		Menu, KodiExitSubMenu, UnCheck, Force Close Kodi instead of Normal Close [for custom shutdown menu only]
		Menu, KodiExitSubMenu, add,
		
	}	
Menu, KodiExitSubMenu, add, Close Kodi on Suspend, MenuCloseKodiOnSuspendHandler
Menu, KodiExitSubMenu, UnCheck, Close Kodi on Suspend

Menu, KodiExitSubMenu, add, Start Windows Explorer when Kodi is closed, MenuStartExplorerHandler
Menu, KodiExitSubMenu, UnCheck, Start Windows Explorer when Kodi is closed
if (OSVersion >= 6.2)
	{
	Menu, KodiExitSubMenu, add, Start Windows8 Metro UI when Kodi is closed, MenuStartMetroUIHandler
	Menu, KodiExitSubMenu, UnCheck, Start Windows8 Metro UI when Kodi is closed
	}
Menu, Tray, add, Kodi Exit Settings, :KodiExitSubMenu
	
Menu, KodiPathSubMenu, add, Set Kodi Path, MenuSetKodiPathHandler
Menu, KodiPathSubMenu, add, Set XBMConiMON Path, MenuSetXBMConiMONPathHandler
Menu, KodiPathSubMenu, add, Set iMON Path, MenuSetiMONPathHandler
Menu, Tray, add, Kodi/iMON Path Settings, :KodiPathSubMenu

Menu, Tray, add ;add separator
shell := RTrim(ShellName, "`.exe")
Menu, Tray, add, Change Windows Shell [Current Shell - %shell%], MenuChangeShellHandler
Menu, Tray, add ;add separator

SplitPath, ExternalPlayer1, ExternalPlayer
if (ExternalPlayer = "")
	ExternalPlayer = Not Set
Menu, ExternalPlayerSubMenu, add, Set External Player 1 - %ExternalPlayer%, MenuSetExternalPlayer1Handler

SplitPath, ExternalPlayer2, ExternalPlayer
if (ExternalPlayer = "")
	ExternalPlayer = Not Set
Menu, ExternalPlayerSubMenu, add, Set External Player 2 - %ExternalPlayer%, MenuSetExternalPlayer2Handler

SplitPath, ExternalPlayer3, ExternalPlayer
if (ExternalPlayer = "")
	ExternalPlayer = Not Set
Menu, ExternalPlayerSubMenu, add, Set External Player 3 - %ExternalPlayer%, MenuSetExternalPlayer3Handler

SplitPath, ExternalPlayer4, ExternalPlayer
if (ExternalPlayer = "")
	ExternalPlayer = Not Set
Menu, ExternalPlayerSubMenu, add, Set External Player 4 - %ExternalPlayer%, MenuSetExternalPlayer4Handler

Menu, ExternalPlayerSubMenu, add,
Menu, ExternalPlayerSubMenu, add, Focus External Player, MenuFocusExternalPlayerHandler
Menu, ExternalPlayerSubMenu, UnCheck, Focus External Player

Menu, Tray, add, External Players and Focus, :ExternalPlayerSubMenu

SplitPath, App1, AppName
if (AppName = "")
	AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 1 - %AppName%, MenuSetApp1Handler

SplitPath, App2, AppName
if (AppName = "")
	AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 2 - %AppName%, MenuSetApp2Handler

SplitPath, App3, AppName
if (AppName = "")
	AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 3 - %AppName%, MenuSetApp3Handler

Menu, ExternalAppsSubMenu, add, Start First Group Applications with KodiLauncher, MenuStartApps1Handler
Menu, ExternalAppsSubMenu, UnCheck, Start First Group Applications with KodiLauncher
Menu, ExternalAppsSubMenu, add, First Group Apps Prevent Kodi Focus, MenuApps1PreventFocusHandler
Menu, ExternalAppsSubMenu, UnCheck, First Group Apps Prevent Kodi Focus

Menu, ExternalAppsSubMenu, add ;add separator

SplitPath, App4, AppName
if (AppName = "")
    AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 4 - %AppName%, MenuSetApp4Handler

SplitPath, App5, AppName
if (AppName = "")
    AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 5 - %AppName%, MenuSetApp5Handler

SplitPath, App6, AppName
if (AppName = "")
    AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 6 - %AppName%, MenuSetApp6Handler

Menu, ExternalAppsSubMenu, add, Start Second Group Applications with KodiLauncher, MenuStartApps2Handler
Menu, ExternalAppsSubMenu, UnCheck, Start Second Group Applications with KodiLauncher
Menu, ExternalAppsSubMenu, add, Second Group Apps Prevent Kodi Focus, MenuApps2PreventFocusHandler
Menu, ExternalAppsSubMenu, UnCheck, Second Group Apps Prevent Kodi Focus

Menu, ExternalAppsSubMenu, add ;add separator

SplitPath, App7, AppName
if (AppName = "")
    AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 7 - %AppName%, MenuSetApp7Handler

SplitPath, App8, AppName
if (AppName = "")
    AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 8 - %AppName%, MenuSetApp8Handler

SplitPath, App9, AppName
if (AppName = "")
    AppName = Not Set
Menu, ExternalAppsSubMenu, add, Set Application 9 - %AppName%, MenuSetApp9Handler

Menu, ExternalAppsSubMenu, add, Start Third Group Applications with KodiLauncher, MenuStartApps3Handler
Menu, ExternalAppsSubMenu, UnCheck, Start Third Group Applications with KodiLauncher
Menu, ExternalAppsSubMenu, add, Third Group Apps Prevent Kodi Focus, MenuApps3PreventFocusHandler
Menu, ExternalAppsSubMenu, UnCheck, Third Group Apps Prevent Kodi Focus


Menu, Tray, add, External Applications, :ExternalAppsSubMenu


Menu, FolderSubMenu, add, Open Kodi Programs Folder, MenuOpenKodiFolderHandler
Menu, FolderSubMenu, add, Open Kodi Application Data Folder, MenuOpenKodiAppFolderHandler
Menu, FolderSubMenu, add
Menu, FolderSubMenu, add, Open KodiLauncher Programs Folder, MenuOpenKodiLauncherFolderHandler
Menu, FolderSubMenu, add, Open KodiLauncher Settings in Regedit, MenuOpenKodiLauncherSettingsHandler
Menu, Tray, add, Application Folders, :FolderSubMenu
Menu, Tray, add
Menu, Tray, add, Turn off Display [Win+F11], MenuTurnOffDisplay
Menu, Tray, add, About KodiLauncher, MenuAboutHandler
Menu, Tray, add
Menu, tray, NoStandard
Menu, tray, Standard

if (FocusOnce = 1)
	Menu, FocusSubMenu, Check, Check Focus Only Once

if (CloseKodiOnSleep = 1)
	Menu, KodiExitSubMenu, Check, Close Kodi on Suspend

if (ForceCloseKodi = 1)
	Menu, KodiExitSubMenu, Check, Force Close Kodi instead of Normal Close [for custom shutdown menu only]

if (StartExplorer = 1)
	Menu, KodiExitSubMenu, Check, Start Windows Explorer when Kodi is closed

if (OSVersion >= 6.2 and StartMetroUI = 1)
	Menu, KodiExitSubMenu, Check, Start Windows8 Metro UI when Kodi is closed

if (StartKodiOnWinLogon = 1)
	Menu, KodiStartSubMenu, Check, Start Kodi When Windows Starts

if (StartKodiOnWinResume = 1)
	Menu, KodiStartSubMenu, Check, Start Kodi When Windows Resumes from Sleep

if (StartKodiInPortableMode = 1)
	Menu, KodiStartSubMenu, Check, Start Kodi in Portable Mode

if (FocusExternalPlayer = 1)
	Menu, ExternalPlayerSubMenu, Check, Focus External Player

if (StartApps1 = 1)
	Menu, ExternalAppsSubMenu, Check, Start First Group Applications with KodiLauncher

if (PreventFocusApps1 = 1)
	Menu, ExternalAppsSubMenu, Check, First Group Apps Prevent Kodi Focus

if (StartApps2 = 1)
	Menu, ExternalAppsSubMenu, Check, Start Second Group Applications with KodiLauncher

if (PreventFocusApps2 = 1)
	Menu, ExternalAppsSubMenu, Check, Second Group Apps Prevent Kodi Focus

if (StartApps3 = 1)
	Menu, ExternalAppsSubMenu, Check, Start Third Group Applications with KodiLauncher

if (PreventFocusApps3 = 1)
	Menu, ExternalAppsSubMenu, Check, Third Group Apps Prevent Kodi Focus

if (DisableFocusPermanently = 1)
	Menu, FocusSubMenu, Check, Disable Focus Permanently
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>		PROMPT FOR Kodi IF NOT FOUND 		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



IfNotExist, %KodiPath% ; if Kodi.exe is not found, prompt to select Kodi.exe manually
	{
		PromptKodiPath := GetSettings("PromptKodiPath", 1)
		if (PromptKodiPath = 1)
		MsgBox, 36, Select Kodi.exe, Could not locate Kodi executable file. Do you want to select the file manually?, 10
		ifMsgBox Yes
		{
			KodiPath := SaveApplicationPath("Kodi", KodiPath)
			if (ShowCustomShutdownMenu = 1)
			{	SplitPath, KodiPath, ,newpath
				FileCopy, %A_WorkingDir%\ShutdownAction.exe, %newpath%, 1
				FileCopy, %A_WorkingDir%\ShutdownAction.py, %newpath%, 1
				FileCopy, %A_WorkingDir%\CloseKodi.exe, %newpath%, 1
				FileCopy, %A_WorkingDir%\CloseKodi.py, %newpath%, 1
				FileCopy, %newpath%\addons\skin.confluence\720p\DialogButtonMenu.xml, %newpath%\addons\skin.confluence\720p\DialogButtonMenu_Backup.xmlbk, 0
				FileCopy, %A_WorkingDir%\DialogButtonMenu.xml, %newpath%\addons\skin.confluence\720p, 1
			}
		}	
		ifMsgBox No
			SaveSettings("PromptKodiPath", 0)
			
	}



; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 			LAUNCH APPLICATIONS 		<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

If (StartKodiOnWinLogon = 1 and ReloadKodiLauncher = 0)
{
	
Sleep %StartupDelay%
LaunchApplication(KodiPath)
WinWait,Kodi,,2 ; wait 2 seconds
WinActivate, ahk_class XBMC ; activate and bring to front.
}


If (StartApps1 = 1 and ReloadKodiLauncher = 0)
{
LaunchApplication(App1)
LaunchApplication(App2)
LaunchApplication(App3)
}

If (StartApps2 = 1 and ReloadKodiLauncher = 0)
{
LaunchApplication(App4)
LaunchApplication(App5)
LaunchApplication(App6)
}

If (StartApps3 = 1 and ReloadKodiLauncher = 0)
{
LaunchApplication(App7)
LaunchApplication(App8)
LaunchApplication(App9)
}

if (ReloadKodiLauncher = 0)
	{LaunchApplication(iMONPath)
	LaunchApplication(XBMConiMONPath)
	}

ReloadKodiLauncher = 0

	; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>	 START Kodi ON WINDOWS RESUME FROM HIBERNATION OR SLEEP 	<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


OnMessage(0x218, "WM_POWERBROADCAST")

WM_POWERBROADCAST(wParam, lParam)

{
	
		
	If (wParam=4) ;suspend
	{
		;BROADCAST_QUERY_DENY := 1112363332
		;return, BROADCAST_QUERY_DENY
		
		Suspending = 1 ;System is suspending. Do not start Explorer.	
		
		if (CloseKodiOnSleep = 1) ; force close Kodi
		{
			Process, Exist, Kodi.exe ; check if Kodi.exe is running 
			If (ErrorLevel > 0) ; If it is running 
			{ 
				Process, Close, %ErrorLevel%  
				Process, WaitClose, %ErrorLevel% 
				sleep 1000
			}
		}
	}	
	
	If (wParam = 7) ;on resuming from suspend state
		{
			Suspending = 0
			If (StartKodiOnWinResume = 1)
			 	{	LaunchApplication(XBMConiMONPath)
			
					Sleep %StartupDelay%
					;WinWait,Kodi,,6 ; wait 6 seconds
					WinActivate, ahk_class XBMC ; activate and bring to front.

					LaunchApplication(KodiPath)
			
					if (DisableFocusTemporarily = 1)
					{
						DisableFocusTemporarily() ;re enable focus
					}		
				
					FocussedOnce = 0
				}				
		}
		
}


;DllCall("kernel32.dll\SetProcessShutdownParameters", UInt, 0x4FF, UInt, 0)
OnMessage(0x11, "WM_QUERYENDSESSION")

WM_QUERYENDSESSION(wParam, lParam)
{
    ENDSESSION_LOGOFF = 0x80000000
    if (lParam & ENDSESSION_LOGOFF)  ; User is logging off.
		ExitApp
        ;EventType = Logoff
    else  ; System is either shutting down or restarting.
        ;EventType = Shutdown
		ExitApp 
}


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> TIMER DECLARATIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


SetTimer, MonitorEvents, 500

MonitorEvents:
KeepFocus()
StartExplorer()
if (OSVersion >= 6.2)
	StartMetroUI() 
MonitorCustomShutdown()
DisableFocusOnExternalPlayer()
return


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  SYSTEM TRAY MENU HANDLERS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


MenuStartKodiHandler:
{
IfNotExist %KodiPath%
	{	MsgBox, 48 , KodiLauncher, Cannot find file "%KodiPath%", 5
		Return
	}
LaunchApplication(KodiPath)
Sleep, 2000
WinActivate, ahk_class XBMC
FocussedOnce = 0
}
return



MenuForceCloseKodiNow:
{
	BreakFocus = 1
		Process, Exist, Kodi.exe ; check if Kodi.exe is running 
			If (ErrorLevel > 0) ; If it is running 
				Process, Close, %ErrorLevel% 
	BreakFocus = 0
}
return


MenuStartExplorer:
{Process, Exist, explorer.exe ; check if explorer.exe is running 
	If (ErrorLevel = 0) 
		Run,  %A_WinDir%\Explorer.exe, %A_WinDir%
	else
		Run ::{20d04fe0-3aea-1069-a2d8-08002b30309d} ;my computer
}
return


MenuShowSettingsGUI:
BreakFocus = 1
IfNotExist %A_ScriptDir%\KodiLauncherGUI.exe
	{	MsgBox, 48 , KodiLauncher, Settings GUI not found., 3
		Return
	}
run %A_ScriptDir%\KodiLauncherGUI.exe	
return

MenuStartKodiAtWindowsLogonHandler:
StartKodiOnWinLogon() 
return

MenuStartKodiAtWindowsResumeHandler:
StartKodiOnWinResume()
return


MenuStartKodiInPortableModeHandler:
StartKodiInPortableModeMode()
return

MenuSetStartupDelayHandler:
SetStartupDelay()
return


MenuSetFocusDelayHandler:
SetFocusDelay()
return

MenuDisableFocusPermanentlyHandler:
DisableFocusPermanently()
return

MenuDisableFocusHandler:
DisableFocusTemporarily()
return

MenuCheckFocusOnceHandler:
CheckFocusOnce()
return

MenuFocusExternalPlayerHandler:
SetFocusExternalPlayer()
return

MenuSetKodiPathHandler:
KodiPath := SaveApplicationPath("Kodi", KodiPath)
return

MenuSetXBMConiMONPathHandler:
XBMConiMONPath := SaveApplicationPath("XBMConiMON", XBMConiMONPath)
return

MenuSetiMONPathHandler:
iMONPath := SaveApplicationPath("iMON", iMONPath)
return

MenuSetExternalPlayer1Handler:
SplitPath, ExternalPlayer1, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
oldmenuname = Set External Player 1 - %ExternalPlayerName%
ExternalPlayer1 := SaveApplicationPath("ExternalPlayer1", ExternalPlayer1)

SplitPath, ExternalPlayer1, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
newmenuname = Set External Player 1 - %ExternalPlayerName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalPlayerSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetExternalPlayer2Handler:
SplitPath, ExternalPlayer2, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
oldmenuname = Set External Player 2 - %ExternalPlayerName%
ExternalPlayer2 := SaveApplicationPath("ExternalPlayer2", ExternalPlayer2)

SplitPath, ExternalPlayer2, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
newmenuname = Set External Player 2 - %ExternalPlayerName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalPlayerSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetExternalPlayer3Handler:
SplitPath, ExternalPlayer3, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
oldmenuname = Set External Player 3 - %ExternalPlayerName%
ExternalPlayer3 := SaveApplicationPath("ExternalPlayer3", ExternalPlayer3)

SplitPath, ExternalPlayer3, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
newmenuname = Set External Player 3 - %ExternalPlayerName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalPlayerSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetExternalPlayer4Handler:
SplitPath, ExternalPlayer4, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
oldmenuname = Set External Player 4 - %ExternalPlayerName%
ExternalPlayer4 := SaveApplicationPath("ExternalPlayer4", ExternalPlayer4)

SplitPath, ExternalPlayer4, ExternalPlayerName
if (ExternalPlayerName = "")
	ExternalPlayerName = Not Set
newmenuname = Set External Player 4 - %ExternalPlayerName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalPlayerSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp1Handler:
SplitPath, App1, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 1 - %AppName%
App1 := SaveApplicationPath("App1", App1)

SplitPath, App1, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 1 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp2Handler:
SplitPath, App2, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 2 - %AppName%
App2 := SaveApplicationPath("App2", App2)

SplitPath, App2, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 2 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp3Handler:
SplitPath, App3, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 3 - %AppName%
App3 := SaveApplicationPath("App3", App3)

SplitPath, App3, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 3 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp4Handler:
SplitPath, App4, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 4 - %AppName%
App4 := SaveApplicationPath("App4", App4)

SplitPath, App4, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 4 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return


MenuSetApp5Handler:
SplitPath, App5, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 5 - %AppName%
App5 := SaveApplicationPath("App5", App5)

SplitPath, App5, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 5 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp6Handler:
SplitPath, App6, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 6 - %AppName%
App6 := SaveApplicationPath("App6", App6)

SplitPath, App6, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 6 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp7Handler:
SplitPath, App7, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 7 - %AppName%
App7 := SaveApplicationPath("App7", App7)

SplitPath, App7, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 7 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp8Handler:
SplitPath, App8, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 8 - %AppName%
App8 := SaveApplicationPath("App8", App8)

SplitPath, App8, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 8 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuSetApp9Handler:
SplitPath, App9, AppName
if (AppName = "")
	AppName = Not Set
oldmenuname = Set Application 9 - %AppName%
App9 := SaveApplicationPath("App9", App9)

SplitPath, App9, AppName
if (AppName = "")
	AppName = Not Set
newmenuname = Set Application 9 - %AppName%

if (oldmenuname != newmenuname)
		{
			menu, ExternalAppsSubMenu, rename, %oldmenuname%, %newmenuname%
		}
return

MenuStartApps1Handler:
SetStartApps1()
return

MenuApps1PreventFocusHandler:
SetPreventFocusApps1()
return

MenuStartApps2Handler:
SetStartApps2()
return

MenuApps2PreventFocusHandler:
SetPreventFocusApps2()
return

MenuStartApps3Handler:
SetStartApps3()
return

MenuApps3PreventFocusHandler:
SetPreventFocusApps3()
return

MenuSetShutdownActionHandler:
SetShutdownAction()
return

MenuCloseKodiOnSuspendHandler:
CloseKodiOnSleep()
return

MenuForceCloseKodiHandler:
SetForceCloseKodi()
return

MenuStartExplorerHandler:
SetStartExplorer()
return

MenuStartMetroUIHandler:
SetStartMetroUI()
return

MenuChangeShellHandler:
ChangeShell()
return

MenuOpenKodiAppFolderHandler:
{
	appfolder := A_AppData . "\Kodi"
	ifexist, %appfolder%
		run %appfolder%
	else
		MsgBox, 48 , KodiLauncher, Folder '%appfolder%' not found., 5
}

return

MenuOpenKodiFolderHandler:
{
	SplitPath, KodiPath, , Kodifolder
	IfExist, %Kodifolder%
		run %Kodifolder%
	else
		MsgBox, 48 , KodiLauncher, Folder '%Kodifolder%' not found., 5
}

return


MenuOpenKodiLauncherFolderHandler:

{
	run %A_ScriptDir%
}

return


MenuOpenKodiLauncherSettingsHandler:
{
	RegWrite, REG_SZ, HKCU, Software\Microsoft\Windows\CurrentVersion\Applets\Regedit, LastKey, HKEY_CURRENT_USER\Software\KodiLauncher
	Run, Regedit.exe
}
return

MenuTurnOffDisplay:
{
	Sleep 1000
	SendMessage 0x112, 0xF170, 2,,Program Manager
}
return


MenuAboutHandler:
{
	BreakFocus = 1
MsgBox KodiLauncher %AppVersion% `n`nAn application to customize your Kodi HTPC. `nDesigned and programmed by baijuxavior@gmail.com`n`n *********************************************************`n`nSpecial credits: `n`n  'EliteGamer360' for GSB code. `n  'Snood' for additional apps support and winkey programming.
}
BreakFocus = 0
return








; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 				FUNCTIONS 					<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


GetSettings(SettingsName, DefaultValue) ;Get settings from registry 
{
	RegRead, result, HKCU, Software\KodiLauncher, %SettingsName%
	if (result = "")
		return %DefaultValue%
	else
		return %result%
}


SaveSettings(SettingsName, Value)
{
	RegWrite,reg_sz,HKCU,Software\KodiLauncher, %SettingsName%, %Value%
}



KeepFocus()
{
		
	if (FocusDelay = 0 or DisableFocusTemporarily = 1 or DisableFocusPermanently = 1 or BreakFocus = 1 or WinActive("ahk_class XBMC"))
		{

			FocusCount = 0
			return
		}
		
	FocusCount := FocusCount + 1
		
		
	If (FocusCount = (FocusDelay * 2) // 1000)
		{
			
			FocusCount = 0
		if (FocusOnce = 0)
			{
			SendFocus()
			return
			}
		
		if (FocusOnce = 1 and FocussedOnce = 0)
			{
			SendFocus()
			FocussedOnce = 1
			}
		}
	
}


SendFocus() ;focus
{
	if (ExternalPlayerRunning = 0)
		{
			Process, Exist, Kodi.exe ; check if Kodi.exe is running 
			If (ErrorLevel > 0)
				IfWinNotActive, ahk_pid %ErrorLevel%
					WinActivate, ahk_pid %ErrorLevel% ;activate Kodi
				{	WinGet, hWnd, ID, ahk_class XBMC ; this snippet is to focus kodi using handle if the above code didn't work.
					WinRestore, ahk_class XBMC
					DllCall("SetForegroundWindow", UInt, hWnd)
				}	
		}
		else ;if externalplayer is running
			if (FocusExternalPlayer = 1)
			{	Process, exist, %ExternalPlayerName%
				If (ErrorLevel > 0)
					IfWinNotActive, ahk_pid %ErrorLevel%
						WinActivate, ahk_pid %ErrorLevel%
			}
		
}


SetFocusDelay() ;function to Change Focus Delay
{
	BreakFocus = 1
	currentdelay := FocusDelay // 1000
	if currentdelay is not number 
		currentdelay = 5
	
	InputBox, Delay, KodiLauncher - Specify Time Delay, Specify the delay between refocussing of Kodi in seconds. `n `nEnter '0' seconds to prevent refocus permanently., , , , , , , , %currentdelay%

	If ErrorLevel ; If cancel was pressed
		{
			;MsgBox cancel
		}
	else
		{
			If Delay is not number
				{
				Delay = 5000
				}
			Else
				{
				Delay := Delay * 1000
				}
		
				SaveSettings("FocusDelay", Delay)
				FocusDelay := Delay
				fdelaynew := FocusDelay // 1000
				old_name = Change Focus Delay [%currentdelay% sec]
				new_name = Change Focus Delay [%fdelaynew% sec]
								
				if (old_name != new_name)
				{
					menu, FocusSubMenu, rename, %old_name%, %new_name%
				}
				
					
		}
		
	BreakFocus = 0	
}



LaunchApplication(AppPath) ; function to start applications
{
SplitPath, AppPath, FileName ;get filename without path
Process, Exist, %FileName% ; check if 'FileName' is running
If (ErrorLevel = 0) ;if not running
	{
	if FileExist(AppPath) 
		{
		if (FileName = "Kodi.exe" and StartKodiInPortableMode = 1) 
			run %AppPath% -p
		else
			run %AppPath%
		}
	Else
		{
		;traytip, Message, %AppPath% not found, 5, 1
		}
	}
	Else ; file already running
	{
	;traytip, Message, %FileName% already running, 5, 1
	}
}


SaveApplicationPath(AppName, StartPath)
{
	BreakFocus = 1
FileSelectFile, SelectedFileName,1 ,%StartPath%, Select %AppName%.exe, *.exe
if SelectedFileName != 
	{
		BreakFocus = 0
		SaveSettings(AppName . "_Path", SelectedFileName)
		return %SelectedFileName%
	}
else
	BreakFocus = 0
	return 	%StartPath%
	
}


StartKodiOnWinLogon()
{
	menu, KodiStartSubMenu, ToggleCheck, Start Kodi When Windows Starts
	if (StartKodiOnWinLogon = 0)
		StartKodiOnWinLogon = 1 ;enable. load Kodi
	else
		StartKodiOnWinLogon = 0 ;disable. don't load
		SaveSettings("StartKodiOnWinLogon", StartKodiOnWinLogon)
		return
}

StartKodiOnWinResume()
{
	menu, KodiStartSubMenu, ToggleCheck, Start Kodi When Windows Resumes from Sleep
	if (StartKodiOnWinResume = 0)
		StartKodiOnWinResume = 1 ;enable. load Kodi
	else
		StartKodiOnWinResume = 0 ;disable. don't load
		
		SaveSettings("StartKodiOnWinResume", StartKodiOnWinResume)
		return
}



StartKodiInPortableModeMode()
{
	menu, KodiStartSubMenu, ToggleCheck, Start Kodi in Portable Mode
	if (StartKodiInPortableMode = 0)
		StartKodiInPortableMode = 1 ;enable. load Kodi in portable mode
	else
		StartKodiInPortableMode = 0 ;disable.
		
		SaveSettings("StartKodiInPortableMode", StartKodiInPortableMode)
		return
}


DisableFocusTemporarily()
{
	menu, FocusSubMenu, ToggleCheck, Disable Focus Temporarily [Win+F9]
	if (DisableFocusTemporarily = 0)
		DisableFocusTemporarily = 1 ;disable focus
	else
		DisableFocusTemporarily = 0 ;enable focus
	
}

DisableFocusPermanently()
{
	menu, FocusSubMenu, ToggleCheck, Disable Focus Permanently
	if (DisableFocusPermanently = 0)
		DisableFocusPermanently = 1 ;disable focus
	else
		DisableFocusPermanently = 0 ;enable focus
	SaveSettings("DisableFocusPermanently", DisableFocusPermanently)
}

DisableFocusOnExternalPlayer()
{
	global appsname
	ExternalPlayerRunning = 0
	
	if (ExternalPlayer1 != "")
	{
		SplitPath, ExternalPlayer1, playername
		Process, exist, %playername%
		If (ErrorLevel > 0)
			{	ExternalPlayerRunning = 1
				ExternalPlayerName = %playername%
			}
	}
	
	if (ExternalPlayer2 != "")
	{
		SplitPath, ExternalPlayer2, playername
		Process, exist, %playername%
		If (ErrorLevel > 0)
			{	ExternalPlayerRunning = 1
				ExternalPlayerName = %playername%
			}
	}
	
	if (ExternalPlayer3 != "")
	{
		SplitPath, ExternalPlayer3, playername
		Process, exist, %playername%
		If (ErrorLevel > 0)
			{	ExternalPlayerRunning = 1
				ExternalPlayerName = %playername%
			}
	}
	
	if (ExternalPlayer4 != "")
	{
		SplitPath, ExternalPlayer4, playername
		Process, exist, %playername%
		If (ErrorLevel > 0)
			{	ExternalPlayerRunning = 1
				ExternalPlayerName = %playername%
			}
	}
	
	if (PreventFocusApps1 = 1)
	{
		if (FileExist(App1))
			{SplitPath, App1, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
		
		if (FileExist(App2))
			{SplitPath, App2, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
		
		if (FileExist(App3))
			{SplitPath, App3, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
	}
	
	if (PreventFocusApps2 = 1)
	{
				
		if (FileExist(App4))
			{SplitPath, App4, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
		
		if (FileExist(App5))
			{SplitPath, App5, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
		
		if (FileExist(App6))
			{SplitPath, App6, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
	}
	
	if (PreventFocusApps3 = 1)
	{
				
		if (FileExist(App7))
			{SplitPath, App7, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
		
		if (FileExist(App8))
			{SplitPath, App8, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
		
		if (FileExist(App9))
			{SplitPath, App9, appsname
			;if (appsname <> "")
			Process, exist, %appsname%
			If (ErrorLevel > 0)
			ExternalPlayerRunning = 1
			}
	}
	
}


CheckFocusOnce()
{
	menu, FocusSubMenu, ToggleCheck, Check Focus Only Once
	if (FocusOnce = 0)
		FocusOnce = 1 ;enable. focus only once
	else
		FocusOnce = 0 ;disable. keep focussing
		SaveSettings("FocusOnce", FocusOnce)
		return
}

SetFocusExternalPlayer()
{
	menu, ExternalPlayerSubMenu, ToggleCheck, Focus External Player
	if (FocusExternalPlayer = 0)
		FocusExternalPlayer = 1 ;enable. focus only once
	else
		FocusExternalPlayer = 0 ;disable. keep focussing
		SaveSettings("FocusExternalPlayer", FocusExternalPlayer)
		return
}

CloseKodiOnSleep()
{
	menu, KodiExitSubMenu, ToggleCheck,Close Kodi on Suspend
	if (CloseKodiOnSleep = 0)
		CloseKodiOnSleep = 1 ;enable
	else
		CloseKodiOnSleep = 0 ;disable
		SaveSettings("CloseKodiOnSleep", CloseKodiOnSleep)
		return
}


SetForceCloseKodi()
{
	menu, KodiExitSubMenu, ToggleCheck,Force Close Kodi instead of Normal Close [for custom shutdown menu only]
	if (ForceCloseKodi = 0)
		ForceCloseKodi = 1 ;enable
	else
		ForceCloseKodi = 0 ;disable
		SaveSettings("ForceCloseKodi", ForceCloseKodi)
		return
}


SetStartExplorer()
{
	menu, KodiExitSubMenu, ToggleCheck,Start Windows Explorer when Kodi is closed
	if (StartExplorer = 0)
		StartExplorer = 1 ;enable
	else
		StartExplorer = 0 ;disable
				
		SaveSettings("StartExplorer", StartExplorer)
		return
}


SetStartMetroUI()
{
	menu, KodiExitSubMenu, ToggleCheck,Start Windows8 Metro UI when Kodi is closed
	if (StartMetroUI = 0)
		StartMetroUI = 1 ;enable
	else
		StartMetroUI = 0 ;disable
				
		SaveSettings("StartMetroUI", StartMetroUI)
		return
}

SetStartApps1()
{
	menu, ExternalAppsSubMenu, ToggleCheck, Start First Group Applications with KodiLauncher
	if (StartApps1 = 0)
		StartApps1 = 1 ;enable. 
	else
		StartApps1 = 0 ;disable. 
		SaveSettings("StartApps1", StartApps1)
		return
}

SetStartApps2()
{
	menu, ExternalAppsSubMenu, ToggleCheck, Start Second Group Applications with KodiLauncher
	if (StartApps2 = 0)
		StartApps2 = 1 ;enable. 
	else
		StartApps2 = 0 ;disable. 
		
		SaveSettings("StartApps2", StartApps2)
		return
}

SetStartApps3()
{
	menu, ExternalAppsSubMenu, ToggleCheck, Start Third Group Applications with KodiLauncher
	if (StartApps3 = 0)
		StartApps3 = 1 ;enable. 
	else
		StartApps3 = 0 ;disable. 
		
		SaveSettings("StartApps3", StartApps3)
		return
}

SetPreventFocusApps1()
{
	menu, ExternalAppsSubMenu, ToggleCheck, First Group Apps Prevent Kodi Focus
	if (PreventFocusApps1 = 0)
		PreventFocusApps1 = 1 ;enable. 
	else
		PreventFocusApps1 = 0 ;disable. 
		
		SaveSettings("PreventFocusApps1", PreventFocusApps1)
		return
}

SetPreventFocusApps2()
{
	menu, ExternalAppsSubMenu, ToggleCheck, Second Group Apps Prevent Kodi Focus
	if (PreventFocusApps2 = 0)
		PreventFocusApps2 = 1 ;enable. 
	else
		PreventFocusApps2 = 0 ;disable. 
		
		SaveSettings("PreventFocusApps2", PreventFocusApps2)
		return
}

SetPreventFocusApps3()
{
	menu, ExternalAppsSubMenu, ToggleCheck, Third Group Apps Prevent Kodi Focus
	if (PreventFocusApps3 = 0)
		PreventFocusApps3 = 1 ;enable. 
	else
		PreventFocusApps3 = 0 ;disable. 
		
		SaveSettings("PreventFocusApps3", PreventFocusApps3)
		return
}

SetShutdownAction() ;function to set shutdown
{
	BreakFocus = 1
	ShutdownAction := GetSettings("ShutdownAction", "u")
	global S1
	global S2
	global S3
	
	
		global currentshutdownaction := "Shutdown"
		If (ShutdownAction = "u")
			currentshutdownaction := "Shutdown"
		If (ShutdownAction = "h")
			currentshutdownaction := "Hibernate"
		If (ShutdownAction = "s")
			currentshutdownaction := "Sleep"
		
	global oldshutdownmenu	:= "Set Shutdown Button Action [for custom shutdown menu only] - " . currentshutdownaction
	
	
	Gui, Add, GroupBox, x1 y4 w350 h111 +Center, Select Kodi Shutdown Menu Action
	Gui, Add, Radio,  % ( ShutdownAction = "u" ? "Checked" : "" ) " x10 y40 w70 h30 vS1" , Shutdown
	Gui, Add, Radio,  % ( ShutdownAction = "s" ? "Checked" : "" ) " x140 y40 w70 h30 vS2" , Sleep
	Gui, Add, Radio,  % ( ShutdownAction = "h" ? "Checked" : "" ) " x250 y40 w70 h30 vS3" , Hibernate
	Gui, Add, Button, x125 y78 w100 h30 , Apply
	Gui, Show, w352 h121, Select Kodi Shutdown Menu Action
	return

	ButtonApply:
	
	global newlabel
   Gui Submit, NoHide 
   Gui Destroy
   If S1
	{
      Result = u
	  newlabel = Shutdown
	}
   If S2
	{
      Result = s
	  newlabel = Sleep
	}
   If S3
	{
      Result = h
	  newlabel = Hibernate
	}
	
	global newshutdownmenu	= "Set Shutdown Button Action [for custom shutdown menu only] - " . newlabel	
	
	if (oldshutdownmenu != newshutdownmenu)
		{
			menu, KodiExitSubMenu, rename, %oldshutdownmenu%, %newshutdownmenu%
		}
	
	SaveSettings("ShutdownAction", Result)	
    	
	GuiClose:
	Gui, Destroy
	BreakFocus = 0
	Return
}



ChangeShell()
{
	RegRead, ShellName, HKCU, Software\Microsoft\Windows NT\CurrentVersion\Winlogon, Shell
	global SelectedShellName := ShellName
	SplitPath, ShellName, ShellName
		global OtherShellName = "Other Shell"
	If(ShellName != "KodiLauncher.exe" and ShellName != "Explorer.exe" and ShellName != "Explorer")
	{	
		OtherShellName := RTrim(ShellName, "`.exe")
		;MsgBox %ShellName%
	}
	
	BreakFocus = 1
	global SH1
	global SH2
	global SH3
	global shelln := RTrim(ShellName, "`.exe")
	global old_shellname := "Change Windows Shell [Current Shell - " . shelln . "]"
		
	Gui, Add, GroupBox, x1 y4 w460 h111 +Center, Change Windows Shell
	Gui, Add, Radio,  % ( Shelln = "Explorer" ? "Checked" : "" ) " x10 y40 w70 h30 vSH1" , Explorer
	Gui, Add, Radio,  % ( Shelln = "KodiLauncher" ? "Checked" : "" ) " x100 y40 w100 h30 vSH2" , KodiLauncher
	Gui, Add, Radio,  % ( Shelln = OtherShellName ? "Checked" : "" ) " x230 y40 w130 h30 vSH3" , %OtherShellName%
	Gui, Add, Button, x380 y40 w70 h30 , Select
	Gui, Add, Button, x180 y78 w100 h30 , Save
	Gui, Show, w463 h121, Change Windows Shell
	return
	
	ButtonSelect:	
		
		FileSelectFile, SelectedShellName,1 ,%ProgFiles%, Select Shell, *.exe
		if SelectedShellName !=
			{
				GuiControl,, %OtherShellName%, 1
				SplitPath, SelectedShellName, NewName
				NewName := RTrim(NewName, "`.exe")
				GuiControl,Text, %OtherShellName%, %NewName%
			}
		;Result = %SelectedFileName%
		;else
		;Result = "Explorer.exe"
		return
	ButtonSave:
	Result = Explorer
   Gui Submit, NoHide 
   Gui Destroy
   If SH1
      {Result = Explorer.exe
	  shelln = Explorer
	  }
   If SH2
      {Result = %A_WorkingDir%\KodiLauncher.exe
      shelln = KodiLauncher
	  }
	  
	If SH3
      {
		Result = %SelectedShellName%
		SplitPath, Result, ShellName
		shelln := RTrim(ShellName, "`.exe")
	  }
    RegWrite, REG_SZ, HKCU, Software\Microsoft\Windows NT\CurrentVersion\Winlogon, Shell, %Result%
	new_shellname = Change Windows Shell [Current Shell - %shelln%]
	
	if (old_shellname != new_shellname)
		{
			menu, tray, rename, %old_shellname%, %new_shellname%
		}
		
	Gui1Close:
	Gui, Destroy
	BreakFocus = 0
	Return
}


MonitorCustomShutdown()
{
	ShutdownButtonClicked := GetSettings("ShutdownButtonClicked", 0)
	if (ShutdownButtonClicked = 1)
	{	
		
			
		Process, Exist, Kodi.exe ; check if Kodi.exe is running 
		If (ErrorLevel = 0) ; If it is closed 
		{ 
			ShutdownAction := GetSettings("ShutdownAction", "u")
			SaveSettings("ShutdownButtonClicked", 0)	
			sleep 1000 ;wait one second
			
			if (ShutdownAction = "u") ;shutdown
				{
					if (OSVersion >= 6.2) ; if windows 8
						{
						if (ForceCloseKodi = 1)
							run, Shutdown.exe -s -hybrid -f -t 00, ,Hide
						else
							run, Shutdown.exe -s -hybrid -t 00, ,Hide
						}
					else
						{
						if (ForceCloseKodi = 1)
							Shutdown, 5 ;shutdown = 1, force = 4
						else
							Shutdown, 1
						}
					ExitApp
				}
				
			if (ShutdownAction = "r") ;reboot
				{
				if (ForceCloseKodi = 1)
					Shutdown, 6 ;reboot = 2, force = 4
				else
					Shutdown, 2
				ExitApp
				}
					
			if (ShutdownAction = "s")	;sleep
				{
				DllCall("PowrProf\SetSuspendState", "int", 0)
				}
				
			if (ShutdownAction = "h")	;hibernate
				{
				DllCall("PowrProf\SetSuspendState", "int", 1)
				}
				
		}
	}
	
	RestartKodi := GetSettings("RestartKodi", 0)
	
	If(RestartKodi = 1)
		{
			Process, Exist, Kodi.exe ; check if Kodi.exe is running 
			If (ErrorLevel > 0) ; If it is running 
			{
				if (ForceCloseKodi = 1)
					Process, Close, %ErrorLevel%  
				else
					WinClose, ahk_class XBMC
					WinWaitClose, ahk_class XBMC
			}
			Loop
			{
				sleep, 1000 ; wait one second
				Process, Exist, Kodi.exe ; check if Kodi.exe is running 
				If (ErrorLevel = 0) ; not running
				{
					LaunchApplication(KodiPath)
					Sleep, 2000
					WinActivate, ahk_class XBMC
					SaveSettings("RestartKodi", 0)
					break
				}
			
			}
						
		}
}



StartExplorer() 
{	
	RestartKodi := GetSettings("RestartKodi", 0)

	If(RestartKodi = 0)
	{
		ShutdownButtonClicked := GetSettings("ShutdownButtonClicked", 0)
		if (StartExplorer = 1 and Suspending = 0 and ShutdownButtonClicked = 0) ;if not suspending
		{
			Process, Exist, Kodi.exe ; check if Kodi.exe is running 
			If (ErrorLevel = 0) ;if not running
				{	Process, Exist, explorer.exe ; check if explorer.exe is running 
					If (ErrorLevel = 0)
						Run,  %A_WinDir%\Explorer.exe, %A_WinDir%
						
					Process, Exist, explorer.exe ; if explorer.exe is not started in previous step 
					If (ErrorLevel = 0)
						Run Explorer.exe
				}	
		}
	}
}



StartMetroUI() 

{
	RestartKodi := GetSettings("RestartKodi", 0)
	If(RestartKodi = 0)
	{
			ShutdownButtonClicked := GetSettings("ShutdownButtonClicked", 0)
			if (StartMetroUI = 1 and Suspending = 0 and ShutdownButtonClicked = 0) ;if not suspending
			{
			Process, Exist, Kodi.exe ; check if Kodi.exe is running 
			If (ErrorLevel = 0) ;if not running
				{
					Process, Exist, explorer.exe ; check if explorer.exe is running 
					If (ErrorLevel = 0)
						Run,  %A_WinDir%\Explorer.exe, %A_WinDir%
					Process, Exist, explorer.exe ; if explorer.exe is not started in previous step 
					If (ErrorLevel = 0)
						Run Explorer.exe
					If (WinKeySent = 0)
						;SendInput {Lwin}
						SendInput ^{Esc} ;Ctrl+Escape Toggles Metro Start screen
						WinKeySent = 1 ;prevents an infinite loop of win key presses
				}
				else
					WinKeySent = 0
			}
	}
}


SetStartupDelay()
{
	BreakFocus = 1
	currentstartupdelay := StartupDelay // 1000
	if currentstartupdelay is not number 
		currentstartupdelay = 0
	
	InputBox, StartDelay, KodiLauncher - Specify Startup Delay, Specify the delay  in seconds for Kodi to start., , , , , , , , %currentstartupdelay%

	If ErrorLevel ; If cancel was pressed
		{
			;MsgBox cancel
		}
	else
		{
			If StartDelay is not number
				{
				StartDelay = 0
				}
			Else
				{
				StartDelay := StartDelay * 1000
				}
				
				StartupDelay := StartDelay
				SaveSettings("StartupDelay", StartupDelay)
				startdelaynew := StartupDelay // 1000
				startdelayold_name = Change Startup Delay [%currentstartupdelay% sec]
				startdelaynew_name = Change Startup Delay [%startdelaynew% sec]
								
				if (startdelayold_name != startdelaynew_name)
				{
					menu, KodiStartSubMenu, rename, %startdelayold_name%, %startdelaynew_name%
				}
				
					
		}
	BreakFocus = 0	
}

return




; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HANDLE KEYBOARD SHORTCUTS FOR GREEN START BUTTON <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#F9:: ;Win+F9
DisableFocusTemporarily()
return

$!F4:: ;Alt+F4
IfWinActive, ahk_class XBMC ; check if Kodi.exe is running 
	{
	Send s
	return
	}
IfWinNotActive, ahk_class XBMCLauncher
	Send !{F4}
	return	

^!F10:: ;show traymenu
#F10:: ;show traymenu
DetectHiddenWindows, on
WinExist( "AHK_Pid " DllCall("GetCurrentProcessId") ) ; make this script's main window the last found window
WinActivate ; even though it's hidden, the target script's main window must be active for the menu to open
SendMessage, 0x404, 0, 0x205 ; AHK_NOTIFYICON = 0x404, WM_RBUTTONUP = 0x205
return

#f11:: ; Turn off Display Screen
;Run,%A_WinDir%\System32\rundll32.exe user32.dll`,LockWorkStation
Sleep 1000
SendMessage 0x112, 0xF170, 2,,Program Manager
return

#E:: ;start explorer
Process, Exist, explorer.exe ; check if explorer.exe is running 
	If (ErrorLevel = 0) 
		{
			Run,  %A_WinDir%\Explorer.exe, %A_WinDir%
			Process, Exist, explorer.exe ; if explorer.exe is not started in previous step 
			If (ErrorLevel = 0)
				Run Explorer.exe
		}
	else
		Run ::{20d04fe0-3aea-1069-a2d8-08002b30309d} ;my computer
return

#S:: ;show settings gui
IfNotExist %A_ScriptDir%\KodiLauncherGUI.exe
	{	MsgBox, 48 , KodiLauncher, Settings GUI not found., 3
		Return
	}
run %A_ScriptDir%\KodiLauncherGUI.exe
return

#!Enter:: ; Win+Alt+Enter shortcut key

IfNotExist %KodiPath%
	{	MsgBox, 48 , KodiLauncher, Cannot find file "%KodiPath%", 5
		Return
	}
	
LaunchApplication(KodiPath)
;Sleep, 2000
WinActivate, ahk_class XBMC
FocussedOnce = 0
LaunchApplication(iMONPath)
LaunchApplication(XBMConiMONPath)
Sleep, 1000
WinActivate, ahk_class XBMC

WinGet, Style, Style, ahk_class XBMC
	if (Style & 0xC00000)  ;Detects if Kodi has a title bar.
		Send {VKDC}  ;Maximize Kodi to fullscreen mode if its in a window mode.
	Return


		SetTitleMatchMode 2
		#IfWinActive ahk_class XBMC ; Kodi detection for Kodi/GSB Home Screen action.
		#!Enter::
		WinGet, Style, Style, ahk_class XBMC
		if (Style & 0xC00000)  ;Detects if Kodi has a title bar.
			Send {VKDC}  ;Maximize Kodi to fullscreen mode if its in a window mode.
		WinMaximize ;Maximize Kodi if Windowed.
		send, ^!{VK74} ; if Kodi is Active (GSB Home Jump will activate)
		Return
		
		
		