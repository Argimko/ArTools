#Warn
#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1
FileEncoding UTF-8-RAW

; https://techcommunity.microsoft.com/t5/Windows-Kernel-Internals/Windows-Sandbox-Config-Files/ba-p/354902


Main()

Main() {
    config := "<Configuration>`n<MappedFolders>`n"
    For n, item In A_Args
    {
        hostFolder := SubStr(item, 4)
        readOnlyState := SubStr(item, 1, 2) = "rw" ? "false" : "true"

        mappedFolder =
        ( LTrim

            <MappedFolder>
            <HostFolder>%hostFolder%</HostFolder>
            <ReadOnly>%readOnlyState%</ReadOnly>
            </MappedFolder>

        )

        config .= mappedFolder
    }
    config .= "`n</MappedFolders>`n</Configuration>"

    configPath := A_MyDocuments "\Windows Sandbox Config.wsb"
    FileDelete % configPath
    FileAppend % config, % configPath

    Run % configPath
}