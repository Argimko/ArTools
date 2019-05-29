#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1
SetWorkingDir %A_ScriptDir%\..\..\..
FileEncoding UTF-8-RAW

#Include <SimpleJSON>


Main()

Main() {
    ; case-insensitive
    If (A_Args[1] = "--clone-to") {
        If (file := FileOpen("Sublime Merge\Data\Local\Session.sublime_session", "rw")) {
            bomLength := file.Position

            json := file.Read()
            json := SimpleJSON.SetRootItem("project_dir", A_Args[2], json)
            json := SimpleJSON.RemoveRootItem("windows", json)

            file.Length := bomLength
            file.Write(json)
            file.Close()
        }

        If (WinExist("ahk_exe sublime_merge.exe")) {
            ControlSend ahk_parent, ^+n
            WinWait Sublime Merge ahk_exe sublime_merge.exe,, 10
            If (!ErrorLevel)
                WinActivate
        }
        Else
            Run Sublime Merge\sublime_merge.exe
    }
}