#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#include %A_ScriptDir%\include\OGdip.ahk


ShowHelpText(settings, leftMargin, topMargin) {
    increaseMapSizeKey := formatHotkeyString(settings["increaseMapSizeKey"])
    decreaseMapSizeKey:= formatHotkeyString(settings["decreaseMapSizeKey"])
    alwaysShowKey:= formatHotkeyString(settings["alwaysShowKey"])
    moveMapLeft:= formatHotkeyString(settings["moveMapLeft"])
    moveMapRight:= formatHotkeyString(settings["moveMapRight"])
    moveMapUp:= formatHotkeyString(settings["moveMapUp"])
    moveMapDown:= formatHotkeyString(settings["moveMapDown"])

    OGdip.Startup()  ; This function initializes GDI+ and must be called first.
    Width := 1800
    Height := 900

    Gui, HelpText: -Caption +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
    gui, HelpText: add, Picture, w%Width% h%Height% x0 y0 hwndHelpText1
    Gui, HelpText: +E0x02000000 +E0x00080000 ; WS_EX_COMPOSITED & WS_EX_LAYERED => Double Buffer

    ; make transparent
    Gui, HelpText: Color,000000
    WinSet,Transcolor, 000000 255

    bmp := new OGdip.Bitmap(Width,Height)  ; Create new empty Bitmap with given width and height
    bmp.GetGraphics()                                  ; .G refers to Graphics surface of this Bitmap, it's used to draw things
    Gui, HelpText: +LastFound

    ; add the title
    YellowBrush:= new OGdip.Brush(0xffFFFF00)
    bmp.G.SetBrush(YellowBrush)
    bmp.G.SetOptions( {textHint:"Antialias"})
    yellowTextFont := new OGdip.Font("Arial", 38, "Bold")
    textFormat := new OGdip.StringFormat(0)
    bmp.G.DrawString("D2R-mapview", yellowTextFont, 20, 0, 0, 0, textFormat)


    ; add the static help text
    WhiteBrush:= new OGdip.Brush(0xFFFFFFFF)
    bmp.G.SetBrush(WhiteBrush)
    bmp.G.SetOptions( {textHint:"Antialias"})
    whiteTextFont := new OGdip.Font("Arial", 21)
    textFormat := new OGdip.StringFormat(0)

    s .= "`n"
    s .= "`n"
    s .= "This MH does not replace the normal automap.`n"
    s .= "It is intended to appear in the top left to assist you.`n"
    s .= "`n"
    s .= "- CTRL+H to show/hide this help`n"
    s .= "- TAB to show/hide map view`n"
    s .= "- " alwaysShowKey " key to permanently show map`n"
    s .= "- " increaseMapSizeKey " key to increase map size`n"
    s .= "- " decreaseMapSizeKey " key to decrease map size`n"
    s .= "- " moveMapLeft " key to move map left`n"
    s .= "- " moveMapRight " key to move map right`n"
    s .= "- " moveMapUp " key to move map up`n"
    s .= "- " moveMapDown " key to move map down`n"
    s .= "- Shift+F10 to exit d2r-mapview`n"
    s .= "`n"
    s .= "You can remap keys, and change colours in settings.ini`n"
    s .= "Configuration options here:`n"
    s .= "https://github.com/joffreybesos/d2r-mapview#configure`n"
    s .= "`n"
    s .= "See log.txt for troubleshooting.`n"
    s .= "`n"
    s .= "Please report scams on the discord, link found on Github.`n"
    bmp.G.DrawString(s, whiteTextFont, 20, 20, 0, 0, textFormat)

    whiteTextFont := new OGdip.Font("Arial", 36)
    bmp.G.DrawString("Press CTRL+H to hide", whiteTextFont, 15, 600, 0, 0, textFormat)

    ; add map legend        
    WhiteBrush:= new OGdip.Brush(0xFFFFFFFF)
    bmp.G.SetBrush(WhiteBrush)
    bmp.G.SetOptions( {textHint:"Antialias"})
    whiteTextFont := new OGdip.Font("Arial", 21)
    textFormat := new OGdip.StringFormat(0)

    alwaysShowKey:= "NumpadMult"
    increaseMapSizeKey:= "NumpadAdd"
    decreaseMapSizeKey:= "NumpadSub"
    m .= "`n"
    m .= "`n"
    m .= " = Player`n"
    m .= " = Normal monster (or NPC)`n"
    m .= " = Unique/Champion/Superunique monster`n"
    m .= " = Boss (Diablo, Nihlithak, Summoner, etc)`n"
    m .= "`n"
    m .= " = Cold immune normal monster`n"
    m .= " = Fire immune normal monster`n"
    m .= " = Poison immune normal monster`n"
    m .= " = Lightning immune normal monster`n"
    m .= " = Magic immune normal monster`n"
    m .= " = Physical immune normal monster`n"
    bmp.G.DrawString(m, whiteTextFont, 700, 20, 0, 0, textFormat)


    pPlayer := new OGdip.Pen(0xff00FF00, 6)
    normalMobColor := 0xff . settings["normalMobColor"] 
    uniqueMobColor := 0xff . settings["uniqueMobColor"] 
    bossColor := 0xff . settings["bossColor"] 

    ; draw dots
    mobx := 687
    moby := 76.6
    rowHeight := 23.9
    dotSize:= 5  
    uDotSize:= 8  
    ldotSize:= 10

    pPenNormal := new OGdip.Pen(normalMobColor, dotSize)
    pPenUnique := new OGdip.Pen(uniqueMobColor, uDotSize)
    pPenBoss := new OGdip.Pen(bossColor, uDotSize)
    pPenExit := new OGdip.Pen(0xff00ff, uDotSize)

    physicalImmuneColor := 0xff . settings["physicalImmuneColor"] 
    magicImmuneColor := 0xff . settings["magicImmuneColor"] 
    fireImmuneColor := 0xff . settings["fireImmuneColor"] 
    lightImmuneColor := 0xff . settings["lightImmuneColor"] 
    coldImmuneColor := 0xff . settings["coldImmuneColor"] 
    poisonImmuneColor := 0xff . settings["poisonImmuneColor"] 

    pPenPhysical := new OGdip.Pen(physicalImmuneColor, dotSize)
    pPenMagic := new OGdip.Pen(magicImmuneColor, dotSize)
    pPenFire := new OGdip.Pen(fireImmuneColor, dotSize)
    pPenLight := new OGdip.Pen(lightImmuneColor, dotSize)
    pPenCold := new OGdip.Pen(coldImmuneColor, dotSize)
    pPenPoison := new OGdip.Pen(poisonImmuneColor, dotSize)

    bmp.G.SetPen(pPlayer).DrawRectangle(mobx+1, moby + (rowHeight * 0), 6, 6)
    
    drawHelpDot(bmp, pPenNormal, mobx+1, moby + (rowHeight * 1), dotsize)
    drawHelpDot(bmp, pPenUnique, mobx, moby + (rowHeight * 2), uDotsize)
    drawHelpDot(bmp, pPenBoss, mobx, moby + (rowHeight * 3), uDotsize)
    drawHelpDot(bmp, pPenCold, mobx, moby + (rowHeight * 5), ldotsize)
    drawHelpDot(bmp, pPenFire, mobx, moby + (rowHeight * 6), ldotsize)
    drawHelpDot(bmp, pPenPoison, mobx, moby + (rowHeight * 7), ldotsize)
    drawHelpDot(bmp, pPenLight, mobx, moby + (rowHeight * 8), ldotsize)
    drawHelpDot(bmp, pPenMagic, mobx, moby + (rowHeight * 9), ldotsize)
    drawHelpDot(bmp, pPenPhysical, mobx, moby + (rowHeight * 10), ldotsize)
    Loop, 6
    {
        drawHelpDot(bmp, pPenNormal, mobx+(dotSize/2), moby + (rowHeight * (4 + A_Index)+(dotSize/2)), dotSize)
    }
    bmp.SetToControl(HelpText1)
    WinGetPos, helpX, helpY, helpWidth, helpHeight, % settings["gameWindowId"]
    helpX:=( helpX + (helpWidth/5) )
    helpY:=( helpY + (helpHeight/5) )
    gui, HelpText: Show, x%helpX% y%helpY% NA ;need to scale?
    Return
}

drawHelpDot(bmp, pen, x, y, dotsize) {
    bmp.G.SetPen(pen).DrawEllipse(x, y, dotSize, dotSize)
}

formatHotkeyString(keyString) {
    ; make hotkey look more logical
    firstChar := SubStr(keyString, 1, 1)
    if (firstChar == "#")
        keyString := StrReplace(keyString, "#", "Win+")
    if (firstChar == "+")
        keyString := StrReplace(keyString, "#", "Shift+")
    if (firstChar == "^")
        keyString := StrReplace(keyString, "#", "Ctrl+")
    if (firstChar == "!")
        keyString := StrReplace(keyString, "#", "Alt+")
    return keyString
}