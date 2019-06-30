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
    A_Args[1] := Common.ExpandEnvironmentStrings(A_Args[1])
    SplitPath % A_Args[1],,, ext,, root
    
    computer := SubStr(root, 1, 2) == "\\" ? root : ""
    
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
    Run *RunAs PsExec\%psExec% %computer% -s -i -d -accepteula %commandLine%,, Hide UseErrorLevel
}