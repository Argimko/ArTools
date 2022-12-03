#Warn
#NoEnv
#SingleInstance Off
#NoTrayIcon

SetBatchLines -1
SetTitleMatchMode 2
SetWorkingDir % A_ScriptDir "\..\..\.."

#Include <Common>

global CPU               := A_Is64bitOS ? "x64" : "x86"
global SUBLIME_TEXT_PATH := A_WorkingDir "\Sublime Text\" CPU "\sublime_text.exe"
global SUBL_PATH         := A_WorkingDir "\Sublime Text\" CPU "\subl.exe"

GroupAdd SublimeText, - Sublime Text ahk_class PX_WINDOW_CLASS


Main()

Main() {
    parts := StrSplit(A_Args[1], ":", "/", 2)
    protocol := parts[1]
    path := Common.PathCreateFromUrl("file:///" RegExReplace(parts[2], "^(%20)+"))

    Switch protocol {
        Case "st":
            SplitPath path, folder
            If (WinExist("(" folder ") ahk_group SublimeText")) {
                WinActivate
            }
            Else {
                SetWorkingDir % path

                files := ""
                Loop Files, %path%\*
                {
                    If (SubStr(A_LoopFileName, 1, 1) != ".")
                        files .= " """ A_LoopFileName """"
                }

                If (WinExist("ahk_group SublimeText")) {
                    Run "%SUBLIME_TEXT_PATH%" .
                    Run "%SUBL_PATH%" --background%files%,, Hide                    
                }
                Else
                    Run "%SUBLIME_TEXT_PATH%" .%files%
            }
    }
}
