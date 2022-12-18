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
    path := Common.PathCreateFromUrl("file:///" RegExReplace(parts[2], "^(%20|\s)+"))

    If (SubStr(path, 1, 14) = "\Google Drive\") {   ; case-insensetive
        SplitPath A_Desktop,, parentPath
        If (FileExist(absPath := parentPath path))
            path := absPath
    }

    Switch protocol {
        Case "st":
            If (attr := FileExist(path)) {
                If (InStr(attr, "D")) {
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
                            If (files != "")
                                Run "%SUBL_PATH%" --background%files%,, Hide                    
                        }
                        Else
                            Run "%SUBLIME_TEXT_PATH%" .%files%
                    }                                    
                }
                Else {
                    Run "%SUBLIME_TEXT_PATH%" "%path%"
                }
            }
            Else {
                MsgBox 0x40030,, File or folder doesn't exists:`n`n%path%
            }
    }
}
