#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1
SetWorkingDir %A_ScriptDir%\..

#Include <Common>


If (A_Args.Length() > 0)
    Main()

Main() {
    computer := ""

    SplitPath % A_Args[1],,, ext,, root
    If (ext != "exe") {
        RegRead className, HKCR\.%ext%
        RegRead command, HKCR\%className%\shell\open\command
        command := StrReplace(command, "%1", A_Args[1])
        A_Args[1] := Trim(StrReplace(command, "%*"))
    }
    Else If (SubStr(root, 1, 2) == "\\")
        computer := root

    commandLine := ""
    For n, param In A_Args
        commandLine .= param " "

    psExec := A_Is64bitOS ? "PsExec64.exe" : "PsExec.exe"
    commandLine := Common.ExpandEnvironmentStrings(commandLine)

    Run *RunAs PsExec\%psExec% %computer% -s -i -d -accepteula %commandLine%,, Hide
}