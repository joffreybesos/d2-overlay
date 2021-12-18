#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%


ReadMobs(d2rprocess, startingOffset, ByRef mobs) {
    ; monsters
    mobs := []
    monstersOffset := startingOffset + 1024
    Loop, 128
    {
        newOffset := monstersOffset + (8 * (A_Index - 1))
        mobAddress := d2rprocess.BaseAddress + newOffset
        mobUnit := d2rprocess.read(mobAddress, "Int64")
        while (mobUnit > 0) { ; keep following the next pointer
            mobType := d2rprocess.read(mobUnit + 0x00, "UInt")
            txtFileNo := d2rprocess.read(mobUnit + 0x04, "UInt")
            if (!HideNPC(txtFileNo)) {
                unitId := d2rprocess.read(mobUnit + 0x08, "UInt")
                mode := d2rprocess.read(mobUnit + 0x0c, "UInt")
                pUnitData := d2rprocess.read(mobUnit + 0x10, "Int64")
                pPath := d2rprocess.read(mobUnit + 0x38, "Int64")
            
                isUnique := d2rprocess.read(pUnitData + 0x18, "UShort")
                monx := d2rprocess.read(pPath + 0x02, "UShort")
                mony := d2rprocess.read(pPath + 0x06, "UShort")
                isBoss := 0
                textTitle := getBossName(txtFileNo)
                if (textTitle) {
                    isBoss:= 1
                }
                isMerc:= getMerc(txtFileNo)
                if (isMerc) {
                    isMerc:= 1
                }
                
                ;get immunities
                pStatsListEx := d2rprocess.read(mobUnit + 0x88, "Int64")
                ownerType := d2rprocess.read(pStatsListEx + 0x08, "UInt")
                ownerId := d2rprocess.read(pStatsListEx + 0x0C, "UInt")

                statPtr := d2rprocess.read(pStatsListEx + 0x30, "Int64")
                statCount := d2rprocess.read(pStatsListEx + 0x38, "Int64")

                immunities := { physical: 0, magic: 0, fire: 0, light: 0, cold: 0, poison: 0 }
                Loop, %statCount%
                {
                    offset := (A_Index -1) * 8
                    ;statParam := d2rprocess.read(statPtr + offset, "UShort")
                    statEnum := d2rprocess.read(statPtr + 0x2 + offset, "UShort")
                    statValue := d2rprocess.read(statPtr + 0x4 + offset, "UInt")
                    if (statValue >= 100) {
                        switch (statEnum) {
                            ; no enums here, just bad practices instead
                            case 36: immunities["physical"] := 1 ;physical immune
                            case 37: immunities["magic"] := 1    ;magic immune
                            case 39: immunities["fire"] := 1     ;fire resist
                            case 41: immunities["light"] := 1    ;light resist
                            case 43: immunities["cold"] := 1     ;cold resist
                            case 45: immunities["poison"] := 1   ;poison resist
                        }
                    }
                }
                mob := {"txtFileNo": txtFileNo, "mode": mode, "x": monx, "y": mony, "isUnique": isUnique, "isBoss": isBoss, "isMerc": isMerc, "textTitle": textTitle, "immunities": immunities}
                mobs.push(mob)
            }
            
            mobUnit := d2rprocess.read(mobUnit + 0x150, "Int64")  ; get next mob
        }
    } 
}


getBossName(txtFileNo) {
    switch (txtFileNo) {
        case "156": return "Andariel"
        case "211": return "Duriel"
        case "229": return "Radament"
        case "242": return "Mephisto"
        case "243": return "Diablo"
        case "250": return "Summoner"
        case "256": return "Izual"
        case "267": return "Bloodraven"
        case "333": return "Diabloclone"
        case "365": return "Griswold"
        case "526": return "Nihlathakboss"
        case "544": return "Baal"
        case "570": return "Baalclone"
        case "704": return "Uber Mephisto"
        case "705": return "Uber Diablo"
        case "706": return "Uber Izual"
        case "707": return "Uber Andariel"
        case "708": return "Uber Duriel"
        case "709": return "Uber Baal"
    }
    return ""
}
getMerc(txtFileNo){
    switch (txtFileNo) {
            case "271": return "roguehire"
            case "338": return "act2hire"
            case "359": return "act3hire"
            case "560": return "act5hire1"
            case "561": return "act5hire2"
        }
        return ""
}
getSuperUniqueName(txtFileNo) {
    switch (txtFileNo) {
        case "0": return "Bonebreak"
        case "5": return "Corpsefire"
        case "11": return "Pitspawn Fouldog"
        case "20": return "Rakanishu"
        case "24": return "Treehead WoodFist"
        case "31": return "Fire Eye"
        case "45": return "The Countess"
        case "47": return "Sarina the Battlemaid"
        case "62": return "Baal Subject 1"
        case "66": return "Flamespike the Crawler"
        case "75": return "Fangskin"
        case "83": return "Bloodwitch the Wild"
        case "92": return "Beetleburst"
        case "97": return "Leatherarm"
        case "103": return "Ancient Kaa the Soulless"
        case "105": return "Baal Subject 2"
        case "120": return "The Tormentor"
        case "125": return "Web Mage the Burning"
        case "129": return "Stormtree"
        case "138": return "Icehawk Riftwing"
        case "160": return "Coldcrow"
        case "276": return "Boneash"
        case "281": return "Witch Doctor Endugu"
        case "284": return "Coldworm the Burrower"
        case "299": return "Taintbreeder"
        case "306": return "Grand Vizier of Chaos"
        case "308": return "Riftwraith the Cannibal"
        case "312": return "Lord De Seis"
        ; case "345": return "Council Member"
        ; case "346": return "Council Member"
        ; case "347": return "Council Member"
        case "362": return "Winged Death"
        case "402": return "The Smith"
        case "409": return "The Feature Creep"
        case "437": return "Bonesaw Breaker"
        case "440": return "Pindleskin"
        case "443": return "Threash Socket"
        case "449": return "Frozenstein"
        case "453": return "Megaflow Rectifier"
        case "472": return "Anodized Elite"
        case "475": return "Vinvear Molech"
        case "479": return "Siege Boss"
        case "481": return "Sharp Tooth Sayer"
        case "494": return "Dac Farren"
        case "496": return "Magma Torquer"
        case "501": return "Snapchip Shatter"
        case "508": return "Axe Dweller"
        case "529": return "Eyeback Unleashed"
        case "533": return "Blaze Ripper"
        case "540": return "Ancient Barbarian 1"
        case "541": return "Ancient Barbarian 2"
        case "542": return "Ancient Barbarian 3"
        case "557": return "Baal Subject 3"
        case "558": return "Baal Subject 4"
        case "571": return "Baal Subject 5"
        case "735": return "The Cow King"
        case "736": return "Dark Elder"
    }
    return ""
}

; certain NPCs we don't want to see such as mercs
HideNPC(txtFileNo) {
    switch (txtFileNo) {
        case 149: return 1 ; chicken
        case 151: return 1 ; rat
        case 152: return 1 ; rogue1
        case 153: return 1 ; hellmeteor
        case 157: return 1 ; bird1
        case 158: return 1 ; bird2
        case 159: return 1 ; bat
        case 195: return 1 ; act2male
        case 196: return 1 ; act2female
        case 197: return 1 ; act2child
        case 179: return 1 ; cow
        case 185: return 1 ; camel
        case 203: return 1 ; act2guard1
        case 204: return 1 ; act2vendor1
        case 205: return 1 ; act2vendor2
        case 268: return 1 ; bug
        case 269: return 1 ; scorpion
        ;case 271: return 1 ; roguehire
        case 272: return 1 ; rogue3
        case 293: return 1 ; familiar
        case 294: return 1 ; firegolem
        case 289: return 1 ; maggotqueen4
        case 290: return 1 ; maggotqueen5
        case 291: return 1 ; claygolem
        case 292: return 1 ; bloodgolem
        case 296: return 1 ; familiar
        case 318: return 1 ; snake
        case 319: return 1 ; parrot
        case 320: return 1 ; fish
        case 321: return 1 ; evilhole1
        case 322: return 1 ; evilhole2
        case 323: return 1 ; evilhole3
        case 324: return 1 ; evilhole4
        case 325: return 1 ; evilhole5
        case 332: return 1 ; invisospawner
        ;case 338: return 1 ; act2hire
        case 339: return 1 ; minispider
        case 344: return 1 ; bonewall
        case 355: return 1 ; seventombs
        case 359: return 1 ; valkyrie
        case 363: return 1 ; megademon2
        case 364: return 1 ; megademon3
        case 370: return 1 ; spiritmummy
        case 377: return 1 ; slinger3
        case 378: return 1 ; slinger4
        case 392: return 1 ; window1
        case 393: return 1 ; window2
        case 401: return 1 ; mephistospirit
        case 411: return 1 ; chargeboltsentry
        case 412: return 1 ; lightningsentry
        case 414: return 1 ; invisopet
        case 415: return 1 ; infernosentry
        case 416: return 1 ; deathsentry
        case 711: return 1 ; demonhole
    }
    return 0
}