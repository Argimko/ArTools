#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1
SetTitleMatchMode 2
SetWorkingDir %A_ScriptDir%
SendMode Input
FileEncoding UTF-8-RAW
Menu Tray, Icon, % A_AhkPath, 2
Menu Tray, Icon

#Include %A_AhkPath%\..\..\Total Commander\ART\ArHotkeys\Globals.ahk

OnMessage(AHK_NOTIFYICON, Func("ExitOnMButton"))
Main()
!F5::Reload


Main() {
    
    
    ExitApp
}