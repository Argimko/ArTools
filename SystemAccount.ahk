#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1
SetWorkingDir %A_ScriptDir%\..

#Include <Common>

; https://superuser.com/questions/136838/which-special-variables-are-available-when-writing-a-shell-command-for-a-context


If (A_Args.Length() > 0)
    Main()

Main() {
    SplitPath % A_Args[1],,, ext
    If (ext != "exe" && ext != "") {
        RegRead className, HKCR\.%ext%
        RegRead command, HKCR\%className%\shell\open\command
        If (!ErrorLevel) {
            command := RegExReplace(command, "i)%[01dlv]\b", A_Args[1])
            A_Args[1] := Trim(RegExReplace(command, "%[*~]"))
        }
    }
    
    commandLine := ""
    For n, param In A_Args
        commandLine .= param " "

    psExec := A_Is64bitOS ? "PsExec64.exe" : "PsExec.exe"
    computer := SubStr(A_Args[1], 1, 2) == "\\" ? "\\" A_ComputerName : ""
    commandLine := Common.ExpandEnvironmentStrings(commandLine)

    Run *RunAs PsExec\%psExec% %computer% -s -i -d -accepteula %commandLine%,, Hide UseErrorLevel
}
