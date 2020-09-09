#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetWinDelay 10
SetBatchLines -1
SetWorkingDir %A_ScriptDir%\..\..\..\Sublime Merge
FileEncoding UTF-8-RAW

#Include <ClipboardStorage>
#Include <SimpleJSON>


Main()

Main() {
    ; case-insensitive
    If (A_Args[1] = "--clone-to") {
        path := A_Args[2]
        If (StrLen(path) > 3)
            path := RTrim(path, "\")

        If (WinExist("ahk_exe sublime_merge.exe")) {
            ClipboardStorage.Store()
            Clipboard := path
            
            ControlSend ahk_parent, ^+n

            ClipWait 10
            WinWait Sublime Merge ahk_exe sublime_merge.exe,, 10
            If (!ErrorLevel) {
                WinActivate
                Send {Tab 2}^+{Backspace}^v{Tab}
            }

            ClipboardStorage.Restore()
        }
        Else {
            If (file := FileOpen("Data\Local\Session.sublime_session", "rw")) {
                bomLength := file.Position

                json := file.Read()
                json := SimpleJSON.SetRootItem("project_dir", path, json)

                file.Length := bomLength
                file.Write(json)
                file.Close()
            }

            Run sublime_merge.exe --new-window
        }
    }
}
