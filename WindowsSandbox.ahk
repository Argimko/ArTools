#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1
FileEncoding UTF-8-RAW

; https://techcommunity.microsoft.com/t5/Windows-Kernel-Internals/Windows-Sandbox-Config-Files/ba-p/354902


Main()

Main() {
    If (!FileExist(A_WinDir "\System32\WindowsSandbox.exe")) {
        MsgBox 0x40030,, Please`, install Windows Sandbox first
        Return
    }

    command := ""
    config := "<Configuration>`n`n<MappedFolders>"

    For n, param In A_Args
    {
        item := StrSplit(param, ":",, 2)

        If (item[1] = "-ro") {
            hostFolder := item[2]
            readOnlyState := "true"
        }
        Else If (item[1] = "-rw") {
            hostFolder := item[2]
            readOnlyState := "false"
        }
        Else If (item[1] = "-cmd") {
            command := item[2]
            Continue
        }
        Else
            Continue

        mappedFolder =
        ( LTrim

            `t<MappedFolder>
            `t`t<HostFolder>%hostFolder%</HostFolder>
            `t`t<ReadOnly>%readOnlyState%</ReadOnly>
            `t</MappedFolder>

        )

        config .= mappedFolder
    }
    config .= "</MappedFolders>"

    If (command != "")
        config .= "`n`n<LogonCommand>`n`t<Command>"""" """ command """</Command>`n</LogonCommand>"

    config .= "`n`n</Configuration>"

    configPath := A_MyDocuments "\Windows Sandbox Config.wsb"
    FileDelete % configPath
    FileAppend % config, % configPath

    Run % configPath
}