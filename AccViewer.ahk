; Accessible Info Viewer
; http://www.autohotkey.com/board/topic/77888-accessible-info-viewer-alpha-release-2012-09-20/
; 2018 EDITED BY ARGIMKO

#Warn
#NoEnv
#NoTrayIcon
#SingleInstance force
#MaxMem 256

#Include <Acc>

SetBatchLines, -1
SetWinDelay 10
Menu Tray, Icon, shell32.dll, 172

{
    global WM_ACTIVATE := 0x06
    global WM_KILLFOCUS := 0x08
    global WM_LBUTTONDOWN := 0x201
    global WM_LBUTTONUP := 0x202
    global Border := new Outline, Stored:={}, Acc := 0, ChildId := 0, TVobj, Win:={}, Lbutton_Pressed := False, CH := False
}
{
    DetectHiddenWindows, On
    OnExit("OnExitCleanup")
    OnMessage(0x200,"WM_MOUSEMOVE")
    ComObjError(false)
    Hotkey, ~LButton Up, Off
}
{
    Gui Main: New, HWND$hwnd LabelGui AlwaysOnTop, Accessible Info Viewer
    Gui Main: Default
    Win.Main := $hwnd
    Gui, Add, Button, x160 y8 w105 h20 vShowStructure gShowStructure, Show Acc Structure
    {
        Gui, Add, Text, x10 y3 w25 h26 Border gCrossHairWrap ReadOnly HWNDh8 Border
        CColor(h8, "White")
        Gui, Add, Text, x10 y3 w25 h4 HWNDh9 Border
        CColor(h9, "0046D5")
        Gui, Add, Text, x13 y17 w19 h1 Border vHBar
        Gui, Add, Text, x22 y8 w1 h19 Border vVBar
    }
    {
        Gui, Font, bold
        Gui, Add, GroupBox, x2 y32 w275 h130 vWinCtrl, Window/Control Info
        Gui, Font
        Gui, Add, Text, x7 y50 w42 h20 Right, WinTitle:
        Gui, Add, Edit, x51 y47 w180 h20 vWinTitle,
        Gui, Add, Button, x+2 y46 w40 h22 gSetTitle, Set
        Gui, Add, Text, x7 y72 w42 h20 Right, Text:
        Gui, Add, Edit, x51 y69 w180 h20 vText,
        Gui, Add, Button, x+2 y68 w40 h22 gSetText, Set
        Gui, Add, Text, x7 y94 w42 h20 vClassText Right, ClassN:
        Gui, Add, Edit, x51 y91 w221 h20 ReadOnly vClass,
        Gui, Add, Text, x7 y116 w42 h20 Right, Hwnd:
        Gui, Add, Edit, x51 y113 w72 h20 ReadOnly vHwnd,
        Gui, Add, Text, x125 y116 w51 h20 Right, Process:
        Gui, Add, Edit, x178 y113 w94 h20 ReadOnly vProcess,
        Gui, Add, Text, x7 y138 w42 h20 Right, Position:
        Gui, Add, Edit, x51 y135 w72 h20 ReadOnly vPosition,
        Gui, Add, Text, x125 y138 w51 h20 Right, Proc ID:
        Gui, Add, Edit, x178 y135 w94 h20 ReadOnly vProcID,
    }
    {
        Gui, Font, bold
        Gui, Add, GroupBox, x2 y165 w275 h130 vAcc, Accessible Info
        Gui, Font
        Gui, Add, Text, x7 y183 w42 h20 Right, Name:
        Gui, Add, Edit, x51 y180 w221 h20 ReadOnly vAccName,
        Gui, Add, Text, x7 y205 w42 h20 Right, Value:
        Gui, Add, Edit, x51 y202 w221 h20 ReadOnly vAccValue,
        Gui, Add, Text, x7 y227 w42 h20 Right, Role:
        Gui, Add, Edit, x51 y224 w85 h20 ReadOnly vAccRole,
        Gui, Add, Edit, x135 y224 w137 h20 ReadOnly vAccRoleValue,
        Gui, Add, Text, x7 y249 w42 h20 Right, State:
        Gui, Add, Edit, x51 y246 w85 h20 ReadOnly vAccState,
        Gui, Add, Edit, x135 y246 w137 h20 ReadOnly vAccStateValue,
        Gui, Add, Text, x7 y271 w42 h20 Right, Action:
        Gui, Add, Edit, x51 y268 w117 h20 ReadOnly vAccAction,
        Gui, Add, Button, x170 y267 w103 h22 vAccDoAction, Do Default Action
        {
            Gui, Add, Text, x7 y293 w55 h20 Right vAccLocationText, Location:
            Gui, Add, Edit, x65 y290 w207 h20 ReadOnly vAccLocation,
            Gui, Add, Text, x7 y315 w55 h20 Right, Description:
            Gui, Add, Edit, x65 y312 w207 h20 ReadOnly vAccDescription,
            Gui, Add, Text, x7 y337 w55 h20 Right, Keyboard:
            Gui, Add, Edit, x65 y334 w207 h20 ReadOnly vAccKeyboard,
            Gui, Add, Text, x7 y359 w55 h20 Right, Help:
            Gui, Add, Edit, x65 y356 w207 h20 ReadOnly vAccHelp,
            Gui, Add, Text, x7 y381 w55 h20 Right, HelpTopic:
            Gui, Add, Edit, x65 y378 w207 h20 ReadOnly vAccHelpTopic,

            Gui, Add, Text, x7 y403 w55 h20 Right, ChildCount:
            Gui, Add, Edit, x65 y400 w35 h20 ReadOnly vAccChildCount,
            
            Gui, Add, Text, x108 y403 h20, Selection:
            Gui, Add, Edit, x158 y400 w35 h20 ReadOnly vAccSelection,
            
            Gui, Add, Text, x202 y403 h20, Focus:
            Gui, Add, Edit, x237 y400 w35 h20 ReadOnly vAccFocus,
        }
    }
    {
        Gui, Add, StatusBar, gShowMainGui
        SB_SetParts(70,150)
        SB_SetText("`tAutofocus: Win+Z", 2)
        SB_SetText("`tshow more", 3)

    }
    {
        Gui Acc: New, ToolWindow AlwaysOnTop Resize LabelAcc HWND$hwnd, Acc Structure
        Win.Acc := $hwnd
        Gui Acc: Add, TreeView, w250 h300 gTreeView R17 AltSubmit
        Gui Acc: Show, Hide
    }
    ShowMainGui()
    WinSet, Redraw, , % "ahk_id " Win.Main
    return
}
ShowMainGui() {
    static ShowingLess := ""
    if A_EventInfo in 1,2
    {
        WM_MOUSEMOVE()
        StatusBarGetText, SB_Text, %A_EventInfo%, % "ahk_id" Win.Main
        if (SB_Text)
            if (A_EventInfo == 2 && (SB_Text:=SubStr(SB_Text,7)) || RegExMatch(SB_Text, "Id: \K\d+", SB_Text))
            {
                ToolTip % "clipboard = " clipboard:=SB_Text
                SetTimer, RemoveToolTip, -2000
            }
    }
    else {
        Gui Main: Default
        if ShowingLess {
            SB_SetText("`tshow less", 3)
            GuiControl, Move, Acc, x2 y165 w275 h262
            GuiControl, Show, AccDescription
            GuiControl, Show, AccLocation
            GuiControl, Show, AccLocationText
            {
                height := 319
                while height<449 {
                    height += 10
                    Gui, Show, w280 h%height%
                    Sleep, 20
                }
            }
            Gui, Show, w280 h451
            ShowingLess := false
        }
        else {
            if (ShowingLess != "") {
                height := 451
                while height>329 {
                    height -= 10
                    Gui, Show, w280 h%height%
                    Sleep, 20
                }
            }
            Gui, Show, w280 h319
            GuiControl, Hide, AccDescription
            GuiControl, Hide, AccLocation
            GuiControl, Hide, AccLocationText
            GuiControl, Move, Acc, x2 y165 w275 h130
            SB_SetText("`tshow more", 3)
            ShowingLess := true
        }
        WinSet, Redraw, , % "ahk_id " Win.Main
    }
return
}

#if !Lbutton_Pressed
#z::
{
    Lbutton_Pressed := true
    Stored.Chwnd := ""
    Gui Acc: Default
    GuiControl, Disable, SysTreeView321
    while, Lbutton_Pressed
    GetAccInfo()
    return
}
#if Lbutton_Pressed
#z::
{
    If (!IsObject(Acc))
        Return

    Lbutton_Pressed := false
    Gui Main: Default
    Sleep, -1
    GuiControl, , WinCtrl, % (DllCall("GetParent", Uint,Acc_WindowFromObject(Acc))? "Control":"Window") " Info"
    if Not DllCall("IsWindowVisible", "Ptr",Win.Acc) {
        Border.Hide()
        SB_SetText("Path: " GetAccPath(Acc).path, 2)
    }
    else {
        Gui Acc: Default
        BuildTreeView()
        GuiControl, Enable, SysTreeView321
        ; WinActivate, % "ahk_id " Win.Acc
        PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id " Win.Acc
    }
    return
}
#if
~Lbutton Up::
@MouseUp() {
    Hotkey, ~LButton Up, Off
    Lbutton_Pressed := False
    Gui Main: Default
    if Not CH {
        GuiControl, Show, HBar
        GuiControl, Show, VBar
        CrossHair(CH:=true)
    }

    If (!IsObject(Acc))
        Return
        
    Sleep, -1
    GuiControl, , WinCtrl, % (DllCall("GetParent", Uint,Acc_WindowFromObject(Acc))? "Control":"Window") " Info"
    if Not DllCall("IsWindowVisible", "Ptr",Win.Acc) {
        Border.Hide()
        SB_SetText("Path: " GetAccPath(Acc).path, 2)
    }
    else {
        Gui Acc: Default
        BuildTreeView()
        GuiControl, Enable, SysTreeView321
        WinActivate, % "ahk_id " Win.Acc
        PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id " Win.Acc
    }
    return
}
CrossHairWrap() {
    if (A_GuiEvent = "Normal") {
        Hotkey, ~LButton Up, On
        {
            GuiControl, Hide, HBar
            GuiControl, Hide, VBar
            CrossHair(CH:=false)
        }
        Lbutton_Pressed := True
        Stored.Chwnd := ""
        Gui Acc: Default
        GuiControl, Disable, SysTreeView321
        while, Lbutton_Pressed
            GetAccInfo()
    }
    return
}
OnExitCleanup() {
    CrossHair(true)
    GuiClose:
    ExitApp
}
ShowStructure() {
    global Lbutton_Pressed, Acc

    ControlFocus, Static1, % "ahk_id " Win.Main
    if DllCall("IsWindowVisible", "Ptr",Win.Acc) {
        PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id " Win.Acc
        return
    }
    WinGetPos, x, y, w, , % "ahk_id " Win.Main
    WinGetPos, , , AccW, AccH, % "ahk_id " Win.Acc
    WinMove, % "ahk_id " Win.Acc,
        , (x+w+AccW > A_ScreenWidth? x-AccW-10:x+w+10)
        , % y+5, %AccW%, %AccH%
    WinShow, % "ahk_id " Win.Acc
    if ComObjType(Acc, "Name") = "IAccessible"
        BuildTreeView()
    if Lbutton_Pressed
        GuiControl, Disable, SysTreeView321
    else
        GuiControl, Enable, SysTreeView321
    PostMessage, %WM_LBUTTONDOWN%, , , SysTreeView321, % "ahk_id " Win.Acc
}
BuildTreeView() {
    r := GetAccPath(Acc)
    AccObj:=r.AccObj, Child_Path:=r.Path, r:=""
    Gui Acc: Default
    TV_Delete()
    GuiControl, -Redraw, SysTreeView321
    parent := TV_Add(Acc_Role(AccObj), "", "Bold Expand")
    TVobj := {(parent): {is_obj:true, obj:AccObj, need_children:false, childid:0, Children:[]}}
    Loop Parse, Child_Path, .
    {
        if A_LoopField is not Digit
            TVobj[parent].Obj_Path := Trim(TVobj[parent].Obj_Path "." A_LoopField, ".")
        else {
            StoreParent := parent
            parent := TV_BuildAccChildren(AccObj, parent, "", A_LoopField)
            TVobj[parent].need_children := false
            TV_Expanded(StoreParent)
            TV_Modify(parent,"Expand")
            AccObj := TVobj[parent].obj
        }
    }
    if Not ChildId {
        TV_BuildAccChildren(AccObj, parent)
        TV_Modify(parent, "Select")
    }
    else
        TV_BuildAccChildren(AccObj, parent, ChildId)
    TV_Expanded(parent)
    GuiControl, +Redraw, SysTreeView321
}
AccClose() {
    Border.Hide()
    Gui Acc: Hide
    TV_Delete()
    Gui Main: Default
    GuiControl, Enable, ShowStructure
}
AccSize() {
    Anchor("SysTreeView321", "wh")
}
TreeView() {
    Gui, Submit, NoHide
    if (A_GuiEvent = "S")
        UpdateInfo(TVobj[A_EventInfo].obj, TVobj[A_EventInfo].childid, TVobj[A_EventInfo].obj_path)
    if (A_GuiEvent = "+") {
        GuiControl, -Redraw, SysTreeView321
        TV_Expanded(A_EventInfo)
        GuiControl, +Redraw, SysTreeView321
    }
}
RemoveToolTip() {
    ToolTip
}
GetAccInfo() {
    global Whwnd
    static ShowButtonEnabled
    MouseGetPos, , , Whwnd
    if (Whwnd!=Win.Main && Whwnd!=Win.Acc && Whwnd!=Border.top && Whwnd!=Border.right && Whwnd!=Border.bottom && Whwnd!=Border.left) {
        {
            GuiControlGet, SectionLabel, , WinCtrl
            if (SectionLabel != "Window/Control Info")
                GuiControl, , WinCtrl, Window/Control Info
        }
        Acc := Acc_ObjectFromPoint(ChildId)
        UpdateInfo(Acc, ChildId)
    }
}
SetText() {
    GuiControlGet, Hwnd,, Hwnd
    GuiControlGet, Text,, Text
    ControlSetText, , % Text, ahk_id %Hwnd%
}
SetTitle() {
    GuiControlGet, Hwnd,, Hwnd
    GuiControlGet, Title,, WinTitle
    WinSetTitle, ahk_id %Hwnd%, , % Title
}
DoAction(Acc, ChildId) {
    Acc.accDoDefaultAction(ChildId)
}
UpdateInfo(Acc, ChildId, Obj_Path := "") {
    Location := Acc_Location(Acc, ChildId).pos
    if (Stored.Location != Location) {
        Hwnd := Acc_WindowFromObject(Acc)
        if (Stored.Hwnd != Hwnd) {
            UpdateWinInfo(Hwnd)
        }
        UpdateAccInfo(Acc, ChildId, Obj_Path)
    }
}
UpdateWinInfo(Hwnd) {
    Gui Main: Default

    ; if (parent := DllCall("GetParent", Uint,hwnd)) {
    ;     WinGetTitle, title, ahk_id %parent%
    ;     try ControlGetText, text, , ahk_id %Hwnd%
    ;     catch e
    ;         text := "# Warning: " e.Message
    ;     className := GetClassNN(Hwnd,Whwnd)
    ;     ControlGetPos, posX, posY, posW, posH, , ahk_id %Hwnd%
    ;     WinGet, proc, ProcessName, ahk_id %parent%
    ;     WinGet, procid, PID, ahk_id %parent%
    ; }
    ; else
    {
        WinGetTitle, title, ahk_id %Hwnd%
        try WinGetText, text, ahk_id %Hwnd%
        catch e
            text := "# Warning: " e.Message
        WinGetClass, className, ahk_id %Hwnd%
        WinGetPos, posX, posY, posW, posH, ahk_id %Hwnd%
        WinGet, proc, ProcessName, ahk_id %Hwnd%
        WinGet, procid, PID, ahk_id %Hwnd%
    }
    {
        GuiControl, , WinTitle, %title%
        GuiControl, , Text, %text%
        GuiControl, , Hwnd, % Format("0x{:X}", Hwnd)
        GuiControl, , Class, %className%
        GuiControl, , Position, x%posX%  y%posY%  w%posW%  h%posH%
        GuiControl, , Process, %proc%
        GuiControl, , ProcId, %procid%
    }
    Stored.Hwnd := Hwnd
}
UpdateAccInfo(Acc, ChildId, Obj_Path) {
    global Whwnd
    Gui Main: Default
    Location := Acc_Location(Acc, ChildId)
    {
        GuiControl, , AccName, % Acc.accName(ChildId)
        GuiControl, , AccValue, % Acc.accValue(ChildId)
        GuiControl, , AccRole, % roleText := Acc_Role(Acc, ChildId)
        GuiControl, , AccRoleValue, % roleText == "" ? "" : "ROLE_" Format("{:U}", StrReplace(roleText, " "))
        GuiControl, , AccState, % Acc_State(Acc, ChildId)
        GuiControl, , AccStateValue, % Acc_StateValue(Acc, ChildId)
        GuiControl, , AccAction, % Acc.accDefaultAction(ChildId)
        doActionHandler := Func("DoAction").Bind(Acc, ChildId)
        GuiControl, +g, AccDoAction, % doActionHandler
        GuiControl, , AccChildCount, % ChildId? "N/A":Acc.accChildCount
        GuiControl, , AccSelection, % ChildId? "N/A":Acc.accSelection
        GuiControl, , AccFocus, % ChildId? "N/A":Acc.accFocus
        GuiControl, , AccLocation, % Location.pos
        GuiControl, , AccDescription, % Acc.accDescription(ChildId)
        GuiControl, , AccKeyboard, % Acc.accKeyboardShortCut(ChildId)
        Guicontrol, , AccHelp, % Acc.accHelp(ChildId)
        GuiControl, , AccHelpTopic, % Acc.accHelpTopic(ChildId)
        SB_SetText(ChildId? " Child Id: " ChildId:" Object")
        SB_SetText(DllCall("IsWindowVisible", "Ptr",Win.Acc)? "Path: " Obj_Path : "`tAutofocus: Win+Z", 2)
    }
    Border.Transparent(true)
    Border.show(Location.x, Location.y, Location.x+Location.w, Location.y+Location.h)
    Border.setabove(Whwnd)
    Border.Transparent(false)
    Stored.Location := Location.pos
}
GetClassNN(Chwnd, Whwnd) {
    global _GetClassNN := {}
    _GetClassNN.Hwnd := Chwnd
    Detect := A_DetectHiddenWindows
    WinGetClass, Class, ahk_id %Chwnd%
    _GetClassNN.Class := Class
    DetectHiddenWindows, On
    EnumAddress := RegisterCallback("GetClassNN_EnumChildProc")
    DllCall("EnumChildWindows", "uint",Whwnd, "uint",EnumAddress)
    DetectHiddenWindows, %Detect%
    return, _GetClassNN.ClassNN, _GetClassNN:=""
}
GetClassNN_EnumChildProc(hwnd, lparam) {
    static Occurrence := 0
    global _GetClassNN
    WinGetClass, Class, ahk_id %hwnd%
    if _GetClassNN.Class == Class
        Occurrence++
    if Not _GetClassNN.Hwnd == hwnd
        return true
    else {
        _GetClassNN.ClassNN := _GetClassNN.Class Occurrence
        Occurrence := 0
        return false
    }
}
TV_Expanded(TVid) {
    For i, TV_Child_ID in TVobj[TVid].Children
        if TVobj[TV_Child_ID].need_children
            TV_BuildAccChildren(TVobj[TV_Child_ID].obj, TV_Child_ID)
}
TV_BuildAccChildren(AccObj, Parent, Selected_Child="", Flag="") {
    Flagged_Child := 0
    TVobj[Parent].need_children := false
    Parent_Obj_Path := Trim(TVobj[Parent].Obj_Path, ".")
    for wach, child in Acc_Children(AccObj) {
        if Not IsObject(child) {
            added := TV_Add("[" A_Index "] " Acc_Role(AccObj, child), Parent)
            TVobj[added] := {is_obj:false, obj:AccObj, childid:child, Obj_Path:Parent_Obj_Path}
            if (child = Selected_Child)
                TV_Modify(added, "Select")
        }
        else {
            added := TV_Add("[" A_Index "] " Acc_Role(child), Parent, "bold")
            TVobj[added] := {is_obj:true, need_children:true, obj:child, childid:0, Children:[], Obj_Path:Trim(Parent_Obj_Path "." A_Index, ".")}
        }
        TVobj[Parent].Children.Insert(added)
        if (A_Index = Flag)
            Flagged_Child := added
    }
    return Flagged_Child
}
GetAccPath(Acc, byref hwnd="") {
    hwnd := Acc_WindowFromObject(Acc)
    WinObj := Acc_ObjectFromWindow(hwnd)
    WinObjPos := Acc_Location(WinObj).pos
    t1 := ""
    t2 := ""
    while Acc_WindowFromObject(Parent:=Acc_Parent(Acc)) = hwnd {
        t2 := GetEnumIndex(Acc) "." t2
        if Acc_Location(Parent).pos = WinObjPos
            return {AccObj:Parent, Path:SubStr(t2,1,-1)}
        Acc := Parent
    }
    while Acc_WindowFromObject(Parent:=Acc_Parent(WinObj)) = hwnd
        t1.="P.", WinObj:=Parent
    return {AccObj:Acc, Path:t1 SubStr(t2,1,-1)}
}
GetEnumIndex(Acc, ChildId=0) {
    if Not ChildId {
        ChildPos := Acc_Location(Acc).pos
        ChildCound := Acc.accChildCount
        For Each, child in Acc_Children(Acc_Parent(Acc))
            ; WARNING! This comparison is NOT 100% guarantee gets the right index
            if IsObject(child) and child.accChildCount=ChildCound and Acc_Location(child).pos=ChildPos
                return A_Index
    }
    else {
        ChildPos := Acc_Location(Acc,ChildId).pos
        For Each, child in Acc_Children(Acc)
            ; WARNING! This comparison is NOT 100% guarantee gets the right index
            if Not IsObject(child) and Acc_Location(Acc,child).pos=ChildPos
                return A_Index
    }
}
WM_MOUSEMOVE() {
    static hCurs := new Cursor(32649)
    MouseGetPos,,,,ctrl
    if (ctrl = "msctls_statusbar321")
        DllCall("SetCursor","ptr",hCurs.ptr)
}
class Cursor {
    __New(id) {
        this.ptr := DllCall("LoadCursor","UInt",0,"Int",id,"UInt")
    }
    __delete() {
        DllCall("DestroyCursor","Uint",this.ptr)
    }
}
class Outline {
    __New(color="red") {
        Gui, +HWNDdefault
        Loop, 4 {
            Gui, New, -Caption +ToolWindow HWNDhwnd
            Gui, Color, %color%
            this[A_Index] := hwnd
        }
        this.visible := false
        this.color := color
        this.top := this[1]
        this.right := this[2]
        this.bottom := this[3]
        this.left := this[4]
        Gui, %default%: Default
    }
    Show(x1, y1, x2, y2, sides="TRBL") {
        Gui, +HWNDdefault
        if InStr( sides, "T" )
            Gui, % this[1] ":Show", % "NA X" x1-2 " Y" y1-2 " W" x2-x1+4 " H" 2
        Else, Gui, % this[1] ":Hide"
        if InStr( sides, "R" )
            Gui, % this[2] ":Show", % "NA X" x2 " Y" y1 " W" 2 " H" y2-y1
        Else, Gui, % this[2] ":Hide"
        if InStr( sides, "B" )
            Gui, % this[3] ":Show", % "NA X" x1-2 " Y" y2 " W" x2-x1+4 " H" 2
        Else, Gui, % this[3] ":Hide"
        if InStr( sides, "L" )
            Gui, % this[4] ":Show", % "NA X" x1-2 " Y" y1 " W" 2 " H" y2-y1
        Else, Gui, % this[3] ":Hide"
        this.visible := true
        Gui, %default%: Default
    }
    Hide() {
        Gui, +HWNDdefault
        Loop, 4
            Gui, % this[A_Index] ": Hide"
        this.visible := false
        Gui, %default%: Default
    }
    SetAbove(hwnd) {
        ABOVE := DllCall("GetWindow", "uint", hwnd, "uint", 3)
        Loop, 4
            DllCall(    "SetWindowPos", "uint", this[A_Index], "uint", ABOVE
                    ,   "int", 0, "int", 0, "int", 0, "int", 0
                    ,   "uint", 0x1|0x2|0x10    )
    }
    Transparent(param) {
        Loop, 4
            WinSet, Transparent, % param=1? 0:255, % "ahk_id " this[A_Index]
        this.visible := !param
    }
    Color(color) {
        Gui, +HWNDdefault
        Loop, 4
            Gui, % this[A_Index] ": Color" , %color%
        this.color := color
        Gui, %default%: Default
    }
    Destroy() {
        Loop, 4
            Gui, % this[A_Index] ": Destroy"
    }
}
CColor(Hwnd, Background="", Foreground="") {
    return CColor_(Background, Foreground, "", Hwnd+0)
}
CColor_(Wp, Lp, Msg, Hwnd) {
    static
    static adrSetTextColor := 0, CTLCOLOR := {}, hwndsBG := {}, hwndsFG := {}, hwnds := {}
    static WM_CTLCOLOREDIT=0x0133, WM_CTLCOLORLISTBOX=0x134, WM_CTLCOLORSTATIC=0x0138
    ,LVM_SETBKCOLOR=0x1001, LVM_SETTEXTCOLOR=0x1024, LVM_SETTEXTBKCOLOR=0x1026, TVM_SETTEXTCOLOR=0x111E, TVM_SETBKCOLOR=0x111D
    ,BS_CHECKBOX=2, BS_RADIOBUTTON=8, ES_READONLY=0x800
    ,CLR_NONE=-1
    ,C := { SILVER:0xC0C0C0, GRAY:0x808080, WHITE:0xFFFFFF, MAROON:0x80, RED:0x0FF, PURPLE:0x800080, FUCHSIA:0xFF00FF,CGREEN:0x8000, LIME:0xFF00, OLIVE:0x8080, YELLOW:0xFFFF, NAVY:0x800000, BLUE:0xFF0000, TEAL:0x808000, AQUA:0xFFFF00 }
    ,CLASSES := "Button,ComboBox,Edit,ListBox,Static,RICHEDIT50W,SysListView32,SysTreeView32"
    If (Msg = "") {
        If (!adrSetTextColor)
        adrSetTextColor   := DllCall("GetProcAddress", "uint", DllCall("GetModuleHandle", "str", "Gdi32.dll"), "str", "SetTextColor")
        ,adrSetBkColor   := DllCall("GetProcAddress", "uint", DllCall("GetModuleHandle", "str", "Gdi32.dll"), "str", "SetBkColor")
        ,adrSetBkMode   := DllCall("GetProcAddress", "uint", DllCall("GetModuleHandle", "str", "Gdi32.dll"), "str", "SetBkMode")
        BG := !Wp ? "" : C[Wp] != "" ? C[Wp] : "0x" SubStr(WP,5,2) SubStr(WP,3,2) SubStr(WP,1,2)
        FG := !Lp ? "" : C[Lp] != "" ? C[Lp] : "0x" SubStr(LP,5,2) SubStr(LP,3,2) SubStr(LP,1,2)
        WinGetClass, class, ahk_id %Hwnd%
        If class not in %CLASSES%
            return A_ThisFunc "> Unsupported control class: " class
        ControlGet, style, Style, , , ahk_id %Hwnd%
        if (class = "Edit") && (Style & ES_READONLY)
            class := "Static"
        if (class = "Button")
            if (style & BS_RADIOBUTTON) || (style & BS_CHECKBOX)
                class := "Static"
            else 
                return A_ThisFunc "> Unsupported control class: " class
        if (class = "ComboBox") {
            VarSetCapacity(CBBINFO, 52, 0), NumPut(52, CBBINFO), DllCall("GetComboBoxInfo", "UInt", Hwnd, "UInt", &CBBINFO)
            hwnd := NumGet(CBBINFO, 48)
            hwndsBG["h" hwnd] := BG, hwndsFG["h" hwnd] := FG, hwnds["h" hwnd] := BG ? DllCall("CreateSolidBrush", "UInt", BG) : -1
            IfEqual, CTLCOLORLISTBOX,,SetEnv, CTLCOLORLISTBOX, % OnMessage(WM_CTLCOLORLISTBOX, A_ThisFunc)
            If NumGet(CBBINFO,44)
                Hwnd :=  Numget(CBBINFO,44), class := "Edit"
        }
        if class in SysListView32,SysTreeView32
        {
            m := class="SysListView32" ? "LVM" : "TVM"
            SendMessage, %m%_SETBKCOLOR, ,BG, ,ahk_id %Hwnd%
            SendMessage, %m%_SETTEXTCOLOR, ,FG, ,ahk_id %Hwnd%
            SendMessage, %m%_SETTEXTBKCOLOR, ,CLR_NONE, ,ahk_id %Hwnd%
            return
        }
        if (class = "RICHEDIT50W")
            return f := "RichEdit_SetBgColor", %f%(Hwnd, -BG)
        if (!CTLCOLOR[Class])
            CTLCOLOR[Class] := OnMessage(WM_CTLCOLOR%Class%, A_ThisFunc)
        return hwnds["h" Hwnd] := BG ? DllCall("CreateSolidBrush", "UInt", BG) : CLR_NONE, hwndsBG["h" hwnd] := BG,  hwndsFG["h" hwnd] := FG
    }
    critical
    Hwnd := Lp + 0, hDC := Wp + 0
    If (hwnds["h" Hwnd]) {
        DllCall(adrSetBkMode, "uint", hDC, "int", 1)
        if (hwndsFG["h" hwnd])
            DllCall(adrSetTextColor, "UInt", hDC, "UInt", hwndsFG["h" hwnd])
        if (hwndsBG["h" hwnd])
            DllCall(adrSetBkColor, "UInt", hDC, "UInt", hwndsBG["h" hwnd])
        return (hwnds["h" Hwnd])
    }
}
CrossHair(OnOff=1) {
    static AndMask, XorMask, $ := "", h_cursor, IDC_CROSS := 32515
    ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13
    , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13
    , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13
    if (OnOff = "Init" or OnOff = "I" or $ = "") {
        $ := "h"
        , VarSetCapacity( h_cursor,4444, 1 )
        , VarSetCapacity( AndMask, 32*4, 0xFF )
        , VarSetCapacity( XorMask, 32*4, 0 )
        , system_cursors := "32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650"
        StringSplit c, system_cursors, `,
        Loop, %c0%
            h_cursor   := DllCall( "LoadCursor", "uint",0, "uint",c%A_Index% )
            , h%A_Index% := DllCall( "CopyImage",  "uint",h_cursor, "uint",2, "int",0, "int",0, "uint",0 )
            , b%A_Index% := DllCall("LoadCursor", "Uint", "", "Int", IDC_CROSS, "Uint")
    }
    $ := (OnOff = 0 || OnOff = "Off" || $ = "h" && (OnOff < 0 || OnOff = "Toggle" || OnOff = "T")) ? "b" : "h"
    Loop, %c0%
        h_cursor := DllCall( "CopyImage", "uint",%$%%A_Index%, "uint",2, "int",0, "int",0, "uint",0 )
        , DllCall( "SetSystemCursor", "uint",h_cursor, "uint",c%A_Index% )
}

/*
    Function: Anchor
        Defines how controls should be automatically positioned relative to the new dimensions of a window when resized.
    Parameters:
        cl - a control HWND, associated variable name or ClassNN to operate on
        a - (optional) one or more of the anchors: 'x', 'y', 'w' (width) and 'h' (height),
            optionally followed by a relative factor, e.g. "x h0.5"
        r - (optional) true to redraw controls, recommended for GroupBox and Button types
    Examples:
> "xy" ; bounds a control to the bottom-left edge of the window
> "w0.5" ; any change in the width of the window will resize the width of the control on a 2:1 ratio
> "h" ; similar to above but directrly proportional to height
    Remarks:
        To assume the current window size for the new bounds of a control (i.e. resetting) simply omit the second and third parameters.
        However if the control had been created with DllCall() and has its own parent window,
            the container AutoHotkey created GUI must be made default with the +LastFound option prior to the call.
        For a complete example see anchor-example.ahk.
        <http://www.autohotkey.net/~polyethene/#anchor>
*/
Anchor(i, a = "", r = false) {
    static c, cs = 12, cx = 255, cl = 0, g, gs = 8, gl = 0, gpi = 0, gw = 0, gh = 0, z = 0, k = 0xffff, ptr
    If z = 0
        VarSetCapacity(g, gs * 99, 0), VarSetCapacity(c, cs * cx, 0), ptr := A_PtrSize ? "Ptr" : "UInt", z := true
    If (!WinExist("ahk_id " . i))
    {
        GuiControlGet, t, Hwnd, %i%
        If ErrorLevel = 0
        i := t
        Else ControlGet, i, Hwnd, , %i%
    }
    VarSetCapacity(gi, 68, 0), DllCall("GetWindowInfo", "UInt", gp := DllCall("GetParent", "UInt", i), ptr, &gi)
    , giw := NumGet(gi, 28, "Int") - NumGet(gi, 20, "Int"), gih := NumGet(gi, 32, "Int") - NumGet(gi, 24, "Int")
    If (gp != gpi)
    {
        gpi := gp
        gf := 0
        Loop, %gl%
            If (NumGet(g, cb := gs * (A_Index - 1)) == gp, "UInt")
            {
                gw := NumGet(g, cb + 4, "Short"), gh := NumGet(g, cb + 6, "Short"), gf := 1
                Break
            }
        If (!gf)
            NumPut(gp, g, gl, "UInt"), NumPut(gw := giw, g, gl + 4, "Short"), NumPut(gh := gih, g, gl + 6, "Short"), gl += gs
    }
    ControlGetPos, dx, dy, dw, dh, , ahk_id %i%
    cf := 0
    Loop, %cl%
    If (NumGet(c, cb := cs * (A_Index - 1), "UInt") == i)
    {
        If a =
        {
            cf = 1
            Break
        }
        giw -= gw, gih -= gh, as := 1, dx := NumGet(c, cb + 4, "Short"), dy := NumGet(c, cb + 6, "Short")
        , cw := dw, dw := NumGet(c, cb + 8, "Short"), ch := dh, dh := NumGet(c, cb + 10, "Short")
        Loop, Parse, a, xywh
            If A_Index > 1
                av := SubStr(a, as, 1), as += 1 + StrLen(A_LoopField)
                , d%av% += (InStr("yh", av) ? gih : giw) * (A_LoopField + 0 ? A_LoopField : 1)
        DllCall("SetWindowPos", "UInt", i, "UInt", 0, "Int", dx, "Int", dy
        , "Int", InStr(a, "w") ? dw : cw, "Int", InStr(a, "h") ? dh : ch, "Int", 4)
        If r != 0
            DllCall("RedrawWindow", "UInt", i, "UInt", 0, "UInt", 0, "UInt", 0x0101)
        Return
    }
    If cf != 1
        cb := cl, cl += cs
    bx := NumGet(gi, 48, "UInt"), by := NumGet(gi, 16, "Int") - NumGet(gi, 8, "Int") - gih - NumGet(gi, 52, "UInt")
    If cf = 1
        dw -= giw - gw, dh -= gih - gh
    NumPut(i, c, cb, "UInt"), NumPut(dx - bx, c, cb + 4, "Short"), NumPut(dy - by, c, cb + 6, "Short")
    , NumPut(dw, c, cb + 8, "Short"), NumPut(dh, c, cb + 10, "Short")
    Return, true
}