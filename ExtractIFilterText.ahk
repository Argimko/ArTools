; IFilter AutoHotkey example by qwerty12
; 
; Credits:
;   https://tlzprgmr.wordpress.com/2008/02/02/using-the-ifilter-interface-to-extract-text-from-documents/
;   https://stackoverflow.com/questions/7177953/loadifilter-fails-on-all-pdfs-but-mss-filtdump-exe-doesnt
;   https://forums.adobe.com/thread/1086426?start=0&tstart=0
;   https://www.autohotkey.com/boards/viewtopic.php?p=80744#p80744
; 
; History:
;   [2018-11-06] https://github.com/qwerty12/AutoHotkeyScripts/blob/master/IFilterPDF/ifilter.ahk
;   [2022-10-30] https://github.com/Ixiko/Addendum-fuer-Albis-on-Windows/blob/master/include/Addendum_PdfHelper.ahk
;   [2022-12-04] https://github.com/Argimko/ArTools/blob/master/ExtractIFilterText.ahk
; 
; Usage examples:
;   ExtractIFilterText(srcPath, dstPath)
;   MsgBox % ExtractIFilterText(srcPath)
;   ExtractIFilterText.ahk "{In}" "{Out}"
;   ExtractIFilterText.ahk ".one"           - Write to the registry OneNote workaround values then exit
;   
; Using with Total Commander MultiArc MVV plugin:
;       wincmd.ini -> [PackerPlugins]:
;           one=320,%COMMANDER_PATH%\PLUGINS\PACKER\MultiArc\MultiArc.wcx
;       MultiArc.ini -> [OneNote]:
;           ID=E4 52 5C 7B 8C D8 A7 4D AE B1 53 78 D0 29 96 D3
;           Extension=one
;           Description=IFilter for OneNote
;           Archiver=C:\AutoHotkey\AutoHotkeyU64.exe \"%COMMANDER_PATH%\Tools\ExtractIFilterText.ahk\" --ext=one
;           Format0=yyyy-tt-dd hh:mm:ss z+ p+ n++
;           BatchUnpack=1
;           List=%PA --list %AQA %O
;           ExtractWithPath=%PA %AQA %FQA

#Warn
#NoEnv
#NoTrayIcon
#SingleInstance Off
SetBatchLines -1

listFile := False
srcPath := dstPath := extForce := ""

For n, param In A_Args {
    ; case-insensetive
    If (param = "--list") {
        listFile := True
    }
    Else If (SubStr(param, 1, 6) = "--ext=") {
        extForce := SubStr(param, 7)
    }
    Else If (srcPath == "") {
        srcPath := param
    }
    Else If (dstPath == "") {
        dstPath := param
    }
}

If (srcPath == "")
    FileSelectFile srcPath, 1,, Source file selecting

If (dstPath == "") {
    SplitPath srcPath,, dir,, filename
    dstPath := dir "\" filename " (text).txt"
}

ExtractIFilterText(srcPath, dstPath, extForce, listFile)

; MsgBox % ExtractIFilterText(srcPath)


ExtractIFilterText(srcPath, dstPath := "", extForce := "", listFile := False, showFilterClsid := False) {
    local

    static STGM_READ                            := 0
    static CHUNK_TEXT                           := 1

    static CHUNK_NO_BREAK                       := 0
    static CHUNK_EOW                            := 1    ; word break
    static CHUNK_EOS                            := 2    ; sentence break
    static CHUNK_EOP                            := 3    ; paragraph break
    static CHUNK_EOC                            := 4    ; chapter break

    static IFILTER_INIT_CANON_PARAGRAPHS        := 1
    static IFILTER_INIT_HARD_LINE_BREAKS        := 2
    static IFILTER_INIT_CANON_HYPHENS           := 4
    static IFILTER_INIT_CANON_SPACES            := 8
    static IFILTER_INIT_APPLY_INDEX_ATTRIBUTES  := 16
    static IFILTER_INIT_APPLY_OTHER_ATTRIBUTES  := 32
    static IFILTER_INIT_INDEXING_ONLY           := 64
    static IFILTER_INIT_SEARCH_LINKS            := 128
    static IFILTER_INIT_APPLY_CRAWL_ATTRIBUTES  := 256
    static IFILTER_INIT_FILTER_OWNED_VALUE_OK   := 512
    static IFILTER_INIT_FILTER_AGGRESSIVE_BREAK := 1024
    static IFILTER_INIT_DISABLE_EMBEDDED        := 2048
    static IFILTER_INIT_EMIT_FORMATTING         := 4096

    static E_FAIL                               := 0x80004005
    static FILTER_S_LAST_TEXT                   := 0x41709
    static FILTER_E_END_OF_CHUNKS               := 0x80041700
    static FILTER_E_NO_MORE_TEXT                := 0x80041701
    static FILTER_E_PASSWORD                    := 0x8004170B

    static WS_DISABLED                          := 0x8000000

    If (!A_IsUnicode)
        Throw A_ThisFunc ": The IFilter APIs appear to be Unicode only, please, try again with a Unicode build of AHK"

    If (!srcPath)
        Return -9
    
    SplitPath srcPath,,, ext, filename
    If (extForce != "")
        ext := extForce

    runIFilter := True
    If (listFile) {
        dstPath := dstText := ""

        ; Save time and do not make unnecessary IFilter calls when unpacking via Total Commander MultiArc plugin:
        ; Total Commander has progress dialog popup when unpacking, so we do not count filesize while list files due unpacking
        WinGet tcStyle, Style, ahk_class TTOTAL_CMD
        runIFilter := !(tcStyle & WS_DISABLED)
    }

    If (runIFilter) {
        ; Adobe workaround
        filterJob := 0
        If (ext = "pdf" && filterJob := DllCall("CreateJobObject", Ptr,0, Str, "filterProc", Ptr))   ; case-insensetive
            DllCall("AssignProcessToJobObject", Ptr,filterJob, Ptr,DllCall("GetCurrentProcess", Ptr))

        ; OneNote workaround - for some reason iFilter OneNote 2016/2021 is not associated with the .one extension, so we need to edit the registry
        ;   - The value {E772CEB3-E203-4828-ADF1-765713D981B8} can be changed to any other value, for example, 1 more than the original OneNote filter
        ;   - The value {B8D12492-CE0F-40AD-83EA-099A03D493F1} must be strictly so, it cannot be changed - taken from [MS Office Filter Packs](https://www.microsoft.com/en-us/download/details.aspx?id=17062)
        ;   - Useful Nir Sofer apps to debug IFilters : SearchFilterView and DocumentTextExtractor
        If (ext = "one") {   ; case-insensetive
            RegRead persistentHandler, HKCR\.one\PersistentHandler
            If (ErrorLevel) {
                RegRead dllPath, HKCR\CLSID\{6EE84065-8BA3-4A8A-9542-6EC8B56A3378}\InprocServer32
                If (!ErrorLevel) {
                    RegRead threadingModel, HKCR\CLSID\{6EE84065-8BA3-4A8A-9542-6EC8B56A3378}\InprocServer32, ThreadingModel

                    RegWrite REG_SZ, HKCU\Software\Classes\.one\PersistentHandler,, {E772CEB3-E203-4828-ADF1-765713D981B8}
                    RegWrite REG_SZ, HKCU\Software\Classes\CLSID\{E772CEB3-E203-4828-ADF1-765713D981B8}\PersistentAddinsRegistered\{89BCB740-6119-101A-BCB7-00DD010655AF},, {B8D12492-CE0F-40AD-83EA-099A03D493F1}
                    RegWrite REG_SZ, HKCU\Software\Classes\CLSID\{B8D12492-CE0F-40AD-83EA-099A03D493F1},, Microsoft OneNote Indexing Filter
                    RegWrite REG_SZ, HKCU\Software\Classes\CLSID\{B8D12492-CE0F-40AD-83EA-099A03D493F1}\InprocServer32,, % dllPath
                    RegWrite REG_SZ, HKCU\Software\Classes\CLSID\{B8D12492-CE0F-40AD-83EA-099A03D493F1}\InprocServer32, ThreadingModel, % threadingModel
                }
            }

            If (srcPath = ".one")   ; case-insensetive
                Return 1
        }

        VarSetCapacity(FILTERED_DATA_SOURCES, 4*A_PtrSize, 0)
        NumPut(&ext,  FILTERED_DATA_SOURCES, 0,         "Ptr")
        VarSetCapacity(filterClsid, 16, 0)

        filterReg := ComObjCreate("{9E175B8D-F52A-11D8-B9A5-505054503030}", "{C7310722-AC80-11D1-8DF3-00C04FB6EF4F}")

        ; ILoadFilter::LoadIFilter
        If (ErrorLevel := DllCall(NumGet(NumGet(filterReg+0)+3*A_PtrSize), Ptr,filterReg, Ptr,0, Ptr,&FILTERED_DATA_SOURCES, Ptr,0, Int,False, Ptr,&filterClsid, Ptr,0, PtrP,0, PtrP,iFilter:=0, UInt))
            Throw Format("0x{:X} - {}: {}", ErrorLevel, A_ThisFunc, "Load IFilter failed for:`n`n""" srcPath """")

        If (showFilterClsid)
            MsgBox,, IFilter CLSID, % GuidToString(filterClsid)

        ObjRelease(filterReg)

        If (ErrorLevel := DllCall("shlwapi\SHCreateStreamOnFile", Str, srcPath, UInt,STGM_READ, PtrP,iStream:=0, UInt))
            Throw Format("0x{:X} - {}: {}", ErrorLevel, A_ThisFunc, "Open input file failed for:`n`n""" srcPath """")

        ; IPersistStream::Load
        persistStream := ComObjQuery(iFilter, "{00000109-0000-0000-C000-000000000046}")
        If (ErrorLevel := DllCall(NumGet(NumGet(persistStream+0)+5*A_PtrSize), Ptr,persistStream, Ptr,iStream, UInt))
            Throw Format("0x{:X} - {}: {}", ErrorLevel, A_ThisFunc, "Load file stream failed for:`n`n""" srcPath """")

        ObjRelease(iStream)

        flags := IFILTER_INIT_HARD_LINE_BREAKS | IFILTER_INIT_CANON_HYPHENS | IFILTER_INIT_CANON_SPACES
               | IFILTER_INIT_INDEXING_ONLY             ; performance optimization
               | IFILTER_INIT_APPLY_INDEX_ATTRIBUTES    ; allow to process Office 2003 file formats like .doc, .xls with offFilt.dll v2008

        ; IFilter::Init
        If (ErrorLevel := DllCall(NumGet(NumGet(iFilter+0)+3*A_PtrSize), Ptr,iFilter, UInt,flags, Int64, 0, Ptr,0, Int64P,0, UInt)) {
            If (ErrorLevel == FILTER_E_PASSWORD)
                Return ErrorLevel
            
            Throw Format("0x{:X} - {}: {}", ErrorLevel, A_ThisFunc, "Init IFilter failed for:`n`n""" srcPath """")
        }
        
        prevBreakType := -1
        bufferSize := 32*1024
        VarSetCapacity(buf, bufferSize * 2 + 2)

        If (dstPath != "") {
            dstFile := FileOpen(dstPath, "w", "UTF-8")
            If (!IsObject(dstFile))
                Throw Format("0x{:X} - {}: {}", A_LastError, A_ThisFunc, "Write text to destination file failed:`n`n""" dstFile """")
        }
        Else
            VarSetCapacity(dstText, bufferSize * 8)

        Loop {
            VarSetCapacity(STAT_CHUNK, A_PtrSize == 8 ? 64 : 52, 0)
            
            ; IFilter::GetChunk
            result := DllCall(NumGet(NumGet(iFilter+0)+4*A_PtrSize), Ptr,iFilter, Ptr,&STAT_CHUNK, UInt)
            If (result == FILTER_E_END_OF_CHUNKS || result == E_FAIL)
                Break

            If (NumGet(STAT_CHUNK, 8, "UInt") & CHUNK_TEXT) {

                breakType := NumGet(STAT_CHUNK, 4, "UInt")
                Switch breakType {
                    Case CHUNK_NO_BREAK : breaks := prevBreakType == CHUNK_EOS ? " " : ""   ; case of Word document hyperlinks
                    Case CHUNK_EOW      : breaks := "`r`n"
                    Case CHUNK_EOP      : breaks := "`r`n`r`n"
                    Case CHUNK_EOC      : breaks := "`r`n`r`n`r`n`r`n`r`n"
                    Default             : breaks := ""
                }

                Loop {
                    ; IFilter::GetText
                    result := DllCall(NumGet(NumGet(iFilter+0)+5*A_PtrSize), Ptr,iFilter, Int64P,length:=bufferSize, Ptr,&buf, UInt)
                    If (result == FILTER_E_NO_MORE_TEXT)
                        Break

                    If (prevBreakType == -1 || A_Index == 2)
                        breaks := ""

                    txt := breaks . StrGet(&buf, length, "UTF-16")

                    ; Workarounds for Office 2003 Word documents processed by offFilt.dll v2008:
                    ;   - replace soft-returns vertical-tabs with hard return
                    ;   - replace table new row double-tabs with hard return
                    If (ext = "doc" || ext = "dot")   ; case-insensetive
                        txt := RegExReplace(txt, "`v|`t`t", "`r`n")
                    
                    dstPath != "" ? dstFile.Write(txt) : dstText .= txt

                    If (result == FILTER_S_LAST_TEXT)
                        Break
                }

                prevBreakType := breakType
            }
        }

        ObjRelease(persistStream)
        ObjRelease(iFilter)

        If (filterJob)
            DllCall("CloseHandle", Ptr,filterJob)
    }

    If (listFile) {
        FileGetTime timestamp, % srcPath
        FormatTime timestamp, % timestamp, yyyy-MM-dd HH:mm:ss
        size := dstText != "" ? StrPut(dstText, "UTF-8") + 2 : 0

        FileAppend %timestamp% %size% %size% %filename% (text).txt, *, cp0
    }
    Else If (dstPath) {
        ; Remove byte order mark if the file has no content
        If (dstFile.Length == 3)
            dstFile.Length := 0

        dstFile.Close()
        
        FileGetTime timestamp, % srcPath
        FileSetTime timestamp, % dstPath
    }
    Else
        Return dstText
}

GuidToString(ByRef pGUID) {
    VarSetCapacity(string, 78)
    DllCall("ole32\StringFromGUID2", Ptr,&pGUID, Str,string, Int,39)
    return string
}

GuidFromString(ByRef GUID, sGUID) {
    VarSetCapacity(GUID, 16, 0)
    DllCall("ole32\CLSIDFromString", Str,sGUID, Ptr,&GUID)
}
