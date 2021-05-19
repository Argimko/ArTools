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
        Run OptionalFeatures.exe
        Return
    }

    command := ""
    config := "<Configuration>`n`n<MappedFolders>"

    mappedFoldersCount := 0
    For n, param In A_Args
    {
        If (SubStr(param, 1, 3) = "-ro" || SubStr(param, 1, 3) = "-rw")
            mappedFoldersCount++
    }

    For n, param In A_Args
    {
        item := StrSplit(param, ":",, 2)

        If (item[1] = "-ro") {
            readOnlyState := "true"
        }
        Else If (item[1] = "-rw") {
            readOnlyState := "false"
        }
        Else If (item[1] = "-cmd") {
            command := item[2]
            Continue
        }
        Else
            Continue

        hostFolder := RTrim(item[2], "\")

        If (mappedFoldersCount == 1 && hostFolder = A_Desktop)
            sandboxFolder := "C:\Users\WDAGUtilityAccount\Desktop"
        Else
            sandboxFolder := ""

        mappedFolder =
        ( LTrim

            `t<MappedFolder>
            `t`t<HostFolder>%hostFolder%</HostFolder>
            `t`t<SandboxFolder>%sandboxFolder%</SandboxFolder>
            `t`t<ReadOnly>%readOnlyState%</ReadOnly>
            `t</MappedFolder>

        )

        config .= mappedFolder
    }
    config .= "</MappedFolders>"

    If (command != "")
        config .= "`n`n<LogonCommand>`n`t<Command>" command "</Command>`n</LogonCommand>"

    config .= "`n`n</Configuration>"

    configPath := A_MyDocuments "\Windows Sandbox Config.wsb"
    FileDelete % configPath
    FileAppend % config, % configPath

    Run % configPath
}