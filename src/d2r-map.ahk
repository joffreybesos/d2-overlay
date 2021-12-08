#SingleInstance, Force
#Persistent
SendMode Input
SetWorkingDir, %A_ScriptDir%
#Include %A_ScriptDir%\include\logging.ahk
#Include %A_ScriptDir%\memory\initMemory.ahk
#Include %A_ScriptDir%\memory\scanOffset.ahk
#Include %A_ScriptDir%\memory\readGameMemory.ahk
#Include %A_ScriptDir%\memory\isAutomapShown.ahk
#Include %A_ScriptDir%\memory\readLastGameName.ahk
#Include %A_ScriptDir%\ui\image\downloadMapImage.ahk
#Include %A_ScriptDir%\ui\showMap.ahk
#Include %A_ScriptDir%\ui\showText.ahk
#Include %A_ScriptDir%\ui\showHelp.ahk
#Include %A_ScriptDir%\ui\showPlayer.ahk
#Include %A_ScriptDir%\ui\showLastGame.ahk
#Include %A_ScriptDir%\readSettings.ahk

expectedVersion := "2.3.0"

if !FileExist(A_Scriptdir . "\settings.ini") {
    MsgBox, , Missing settings, Could not find settings.ini file
    ExitApp
}

IniRead, version, settings.ini, VersionControl, version, ""
if (version != expectedVersion) {
    MsgBox, , Mismatched settings version, Your settings.ini is not the expected version %expectedVersion%`nIn future please update executable AND settings.ini`nPress OK to continue anyway   
}

lastMap := ""
exitArray := []
helpToggle:= true
WriteLog("*******************************************************************")
WriteLog("* Map overlay started https://github.com/joffreybesos/d2r-mapview *")
WriteLog("*******************************************************************")
WriteLog("Please report issues in #support on discord: https://discord.gg/qEgqyVW3uj")
WriteLog("This map hack may not work on Windows 11")

readSettings(settings.ini, settings)

playerOffset := settings["playerOffset"]
startingOffset := settings["playerOffset"]
readInterval := settings["readInterval"]
uiOffset := settings["uiOffset"]
lastlevel:=""
lastSeed:=""
lastGameStartTime:=0
uidata:={}

global debug := settings["debug"]
global gameWindowId := settings["gameWindowId"]
global gameStartTime:=0

increaseMapSizeKey := settings["increaseMapSizeKey"]
decreaseMapSizeKey := settings["decreaseMapSizeKey"]
alwaysShowKey := settings["alwaysShowKey"]

Hotkey, IfWinActive, ahk_exe D2R.exe
Hotkey, %alwaysShowKey%, MapSizeAlwaysShow
Hotkey, IfWinActive, ahk_exe D2R.exe
Hotkey, %increaseMapSizeKey%, MapSizeIncrease
Hotkey, IfWinActive, ahk_exe D2R.exe
Hotkey, %decreaseMapSizeKey%, MapSizeDecrease

moveMapLeftKey := settings["moveMapLeft"]
moveMapRightKey := settings["moveMapRight"]
moveMapUpKey := settings["moveMapUp"]
moveMapDownKey := settings["moveMapDown"]

Hotkey, IfWinActive, ahk_exe D2R.exe
Hotkey, %moveMapLeftKey%, MoveMapLeft
Hotkey, IfWinActive, ahk_exe D2R.exe
Hotkey, %moveMapRightKey%, MoveMapRight
Hotkey, IfWinActive, ahk_exe D2R.exe
Hotkey, %moveMapUpKey%, MoveMapUp
Hotkey, IfWinActive, ahk_exe D2R.exe
Hotkey, %moveMapDownKey%, MoveMapDown

; initialise memory reading
d2rprocess := initMemory(gameWindowId)

; create GUI windows
Gui, GameInfo: -Caption +E0x20 +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
gamenameHwnd1 := WinExist()

Gui, Map: -Caption +E0x20 +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
mapHwnd1 := WinExist()

Gui, Units: -Caption +E0x20 +E0x80000 +E0x00080000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs 
unitHwnd1 := WinExist()

offsetAttempts := 6
While 1 {
    ; scan for the player offset
    playerOffset := scanOffset(d2rprocess, playerOffset, startingOffset, uiOffset)

    if (!playerOffset) {
        offsetAttempts += 1
        if (offsetAttempts > 5) {
            WriteLogDebug("Could not find playerOffset, likely in menu " gameStartTime)
            hideMap(false)
            lastlevel:=
            
            if (gameStartTime > 0) {
                SetFormat Integer, D
                gameStartTime += 0
                lastGameDuration := (A_TickCount - gameStartTime)/1000.0
                WriteTimedLog()
                gameStartTime := 0
            }
            if (settings["showGameInfo"]) {
                lastGameName := readLastGameName(d2rprocess, gameWindowId, settings)
                ShowGameText(lastGameName, gamenameHwnd1, lastGameDuration, gameWindowId)
            }
            offsetAttempts := 6
        }
        Sleep, 500 ; sleep longer when no offset found, you're likely in menu
    } else {
        offsetAttempts := 0
        Gui, GameInfo: Hide  ; hide the last game info
        readGameMemory(d2rprocess, settings, playerOffset, gameMemoryData)

        if ((gameMemoryData["difficulty"] > 0 & gameMemoryData["difficulty"] < 3) and (gameMemoryData["levelNo"] > 0 and gameMemoryData["levelNo"] < 137) and gameMemoryData["mapSeed"]) {
            if (gameMemoryData["mapSeed"] != lastSeed) {
                gameStartTime := A_TickCount    
                WriteLog("Start time: " gameStartTime)
                lastSeed := gameMemoryData["mapSeed"]
            }
            ; if there's a level num then the player is in a map
            if (gameMemoryData["levelNo"] != lastlevel) { ; only redraw map when it changes
                
                ; Show loading text
                ;Gui, Map: Show, NA
                Gui, Map: Hide ; hide map
                Gui, Units: Hide ; hide player dot
                ShowText(settings, "Loading map data...`nPlease wait`nPress Ctrl+H for help", "44") ; 22 is opacity
                ; Download map
                downloadMapImage(settings, gameMemoryData, imageData)
                Gui, LoadingText: Destroy ; remove loading text
                ; Show Map
                if (lastlevel == "") {
                    Gui, Map: Show, NA
                    Gui, Units: Show, NA
                }
                ShowMap(settings, mapHwnd1, imageData, gameMemoryData, uiData)
            }
            ; update player layer on each loop
            ShowPlayer(settings, unitHwnd1, imageData, gameMemoryData, uiData)
            checkAutomapVisibility(d2rprocess, settings, gameMemoryData["levelNo"])

            lastlevel := gameMemoryData["levelNo"]
        } else {
            WriteLog("In Menu - no valid difficulty, levelno, or mapseed found '" gameMemoryData["difficulty"] "' '" gameMemoryData["levelNo"] "' '" gameMemoryData["mapSeed"] "'")
            hideMap(false)
            lastlevel:=
        }
    }
    Sleep, %readInterval% ; this is the pace of updates
}

checkAutomapVisibility(d2rprocess, settings, levelNo) {
    uiOffset:= settings["uiOffset"]
    alwaysShowMap:= settings["alwaysShowMap"]
    hideTown:= settings["hideTown"]
    ;WriteLogDebug("Checking visibility, hideTown: " hideTown " alwaysShowMap: " alwaysShowMap)
    if ((levelNo == 1 or levelNo == 40 or levelNo == 75 or levelNo == 103 or levelNo == 109) and hideTown) {
        ;WriteLogDebug("Hiding town " levelNo " since hideTown is set to true")
        hideMap(false)
    } else if not WinActive(gameWindowId) {
        ;WriteLogDebug("D2R is not active window, hiding map")
        hideMap(false)
    } else if (!isAutomapShown(d2rprocess, uiOffset) and !alwaysShowMap) {
        ; hidemap
        hideMap(alwaysShowMap)
    } else {
        unHideMap()
    } 
    return
}

hideMap(alwaysShowMap) {
    if (alwaysShowMap == false) {
        ;WriteLogDebug("Hide map, alwaysShowMap was set to false")
        Gui, Map: Hide
        Gui, Units: Hide
    }
}

unHideMap() {
    ;showmap
    ;WriteLogDebug("Map shown")
    Gui, Map: Show, NA
    Gui, Units: Show, NA
}


+F10::
{
    WriteLog("Pressed Shift+F10, exiting...")
    WriteTimedLog()
    ExitApp
}


MapSizeAlwaysShow:
{
    settings["alwaysShowMap"] := !settings["alwaysShowMap"]
    checkAutomapVisibility(d2rprocess, settings, gameMemoryData["levelNo"])
    if (settings["alwaysShowMap"]) {
        unHideMap()
        IniWrite, true, settings.ini, MapSettings, alwaysShowMap
    } else {
        IniWrite, false, settings.ini, MapSettings, alwaysShowMap
    }
    WriteLog("alwaysShowMap set to " settings["alwaysShowMap"])
    return
}

MapSizeIncrease:
{
    levelNo := gameMemoryData["levelNo"]
    levelScale := imageData["levelScale"]
    if (levelNo and levelScale) {
        levelScale := levelScale + 0.05
        IniWrite, %levelScale%, mapconfig.ini, %levelNo%, scale
        imageData["levelScale"] := levelScale
        ShowMap(settings, mapHwnd1, imageData, gameMemoryData, uiData)
        ShowPlayer(settings, unitHwnd1, imageData, gameMemoryData, uiData)
        WriteLog("Increased level " levelNo " scale by 0.05 to " levelScale)
    }
    return
}

MapSizeDecrease:
{
    levelNo := gameMemoryData["levelNo"]
    levelScale := imageData["levelScale"]
    if (levelNo and levelScale) {
        levelScale := levelScale - 0.05
        IniWrite, %levelScale%, mapconfig.ini, %levelNo%, scale
        imageData["levelScale"] := levelScale
        ShowMap(settings, mapHwnd1, imageData, gameMemoryData, uiData)
        ShowPlayer(settings, unitHwnd1, imageData, gameMemoryData, uiData)
        WriteLog("Decreased level " levelNo " scale by 0.05 to " levelScale)
    }
    return
}
    
#IfWinActive, ahk_exe D2R.exe
    MoveMapLeft:
    {
        levelNo := gameMemoryData["levelNo"]
        levelxmargin := imageData["levelxmargin"]
        levelymargin := imageData["levelymargin"]
        if (levelNo) {
            levelxmargin := levelxmargin - 25
            IniWrite, %levelxmargin%, mapconfig.ini, %levelNo%, x
            imageData["levelxmargin"] := levelxmargin
            ShowMap(settings, mapHwnd1, imageData, gameMemoryData, uiData)
            ShowPlayer(settings, unitHwnd1, imageData, gameMemoryData, uiData)
        }
        return
    }
    MoveMapRight:
    {
        levelNo := gameMemoryData["levelNo"]
        levelxmargin := imageData["levelxmargin"]
        levelymargin := imageData["levelymargin"]
        if (levelNo) {
            levelxmargin := levelxmargin + 25
            IniWrite, %levelxmargin%, mapconfig.ini, %levelNo%, x
            imageData["levelxmargin"] := levelxmargin
            ShowMap(settings, mapHwnd1, imageData, gameMemoryData, uiData)
            ShowPlayer(settings, unitHwnd1, imageData, gameMemoryData, uiData)
        }
        return
    }
    MoveMapUp:
    {
        levelNo := gameMemoryData["levelNo"]
        levelxmargin := imageData["levelxmargin"]
        levelymargin := imageData["levelymargin"]
        if (levelNo) {
            levelymargin := levelymargin - 25
            IniWrite, %levelymargin%, mapconfig.ini, %levelNo%, y
            imageData["levelymargin"] := levelymargin
            ShowMap(settings, mapHwnd1, imageData, gameMemoryData, uiData)
            ShowPlayer(settings, unitHwnd1, imageData, gameMemoryData, uiData)
        }
        return
    }
    MoveMapDown:
    {
        levelNo := gameMemoryData["levelNo"]
        levelxmargin := imageData["levelxmargin"]
        levelymargin := imageData["levelymargin"]
        if (levelNo) {
            levelymargin := levelymargin + 25
            IniWrite, %levelymargin%, mapconfig.ini, %levelNo%, y
            imageData["levelymargin"] := levelymargin
            ShowMap(settings, mapHwnd1, imageData, gameMemoryData, uiData)
            ShowPlayer(settings, unitHwnd1, imageData, gameMemoryData, uiData)
        }
        return
    }
    ^H::
    {
        if (helpToggle) {
            ShowHelpText(settings, 400, 200)
            WriteLogDebug("Show Help")
        } else {
            Gui, HelpText: Hide
            WriteLogDebug("Hide Help")
        }
        helpToggle := !helpToggle
        return
    }
    ~TAB::
    ~Space::
    {
        checkAutomapVisibility(d2rprocess, settings, gameMemoryData["levelNo"])
        return
    }
    ~Esc::
    {
        Gui, HelpText: Hide
        helpToggle := 1
        WriteLogDebug("Hide Help")
    }
return

