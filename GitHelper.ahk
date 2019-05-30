#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetWinDelay 10
SetBatchLines -1
SetWorkingDir %A_ScriptDir%\..\..\..
FileEncoding UTF-8-RAW

#Include <ClipboardStorage>
#Include <SimpleJSON>


Main()

Main() {
    ; case-insensitive
    If (A_Args[1] = "--clone-to") {
        If (WinExist("ahk_exe sublime_merge.exe")) {
            ClipboardStorage.Store()
            Clipboard := A_Args[2]
            
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
            If (file := FileOpen("Sublime Merge\Data\Local\Session.sublime_session", "rw")) {
                bomLength := file.Position

                json := file.Read()
                json := SimpleJSON.SetRootItem("project_dir", A_Args[2], json)
                json := SimpleJSON.RemoveRootItem("windows", json)

                file.Length := bomLength
                file.Write(json)
                file.Close()
            }

            Run Sublime Merge\sublime_merge.exe
        }
    }
}