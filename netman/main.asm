    device zxspectrum48
    org #8000
start:
    di
    ld sp, start - 1
    res 4, (iy+1)
    xor a : out (#fe), a : call changeBank

    call clearScreen
    ld hl, initing : call putStringZ
    call uartBegin
    ei
    halt
    call setSpeed
    IFDEF PLUS3DOS    
    call initDos
    ld ix, DOS_MOTOR_OFF : call plus3dos 
    ENDIF
    ld b, #ff ; flush uart shit
.preRead
    push bc
    call uartRead
    pop bc
    djnz .preRead
    
    call clearScreen
    call initWifi
    
    ld a, 0, hl, buffer, bc, 2048, de, buffer + 1, (hl), a
    ldir 
    ld hl, getNetwork : call uartWriteStringZ
    call clearScreen
.skipShit
    call readSilient
    cp '+'
    jr nz, .skipShit

    call clearScreen
    call clearRing
    ld hl, buffer
.rlp
    push hl
    call uartReadBlocking
    pop hl
    ld (hl), a
    inc hl
    push hl
    call pushRing
    ld hl, response_ok : call searchRing : cp 1 : jr z, .dp 
    pop hl
    jp .rlp
.dp:    
    pop hl
    xor a 
    .7 dec hl : ld (hl), a
dbgEntry:
    call drawPage
    ei
    xor a : ld (CURKEY), a
inputLoop:
    halt
    call inkey : or a : jr z, inputLoop
    push af 
    call hideCursor
    pop af
    cp 'q' : jp z, moveUp
    cp 'a' : jp z, moveDown
    cp 13  : jp z, selectItem
    call showCursor
    jp inputLoop    

ssid  ds 80
pass  ds 80

    IFDEF PLUS3DOS
cfg db "iw.cfg", #ff
    ENDIF 

    IFDEF ESXDOS
cfg db "/sys/config/iw.cfg", 0
fp  db 0
    ENDIF

selectItem:
    ld a, (cursor_pos) : dec a : ld b, a
    call findLine : call findName
    ld de, ssid
.copyName
    ld a, (hl)
    cp '"' : jr z, .next
    ldi 
    jp .copyName
.next:
    ld a, (ssid) : and a : jp z, doNothing 
    call prepHeader
    ld b, 19 : ld c, 0 : call gotoXY
    ld hl, enterpwd : call putStringZ
    
    call input
    ld hl, iBuff : ld de, pass : ld bc, 64 : ldir
    
    IFDEF PLUS3DOS    
    ld hl, cfg
    ld c, ACCESS_MODE_EXCLUSIVE_WRITE, d, CREATE_ACTION_POINT_TO_DATA, e, OPEN_ACTION_MAKE_BACKUP
    call fopen

    ld c, 0, de, 160, hl, ssid 
    call fwrite
    call fclose
    ENDIF

    IFDEF ESXDOS
    ld hl, cfg, b, FMODE_CREATE
    call fopen
    ld (fp), a
    ld hl, ssid, bc, 160
    call fwrite
    ld a, (fp)
    call fclose
    ENDIF

    ld b, 2 : ld c, 0 : call gotoXY
    ld hl, allDone : call putStringZ

    jr $
    ret

moveUp:
    ld a, (cursor_pos) : dec a : or a : jp z, doNothing
    ld (cursor_pos), a
    call showCursor
    jp inputLoop

moveDown:
    ld a, (cursor_pos) : inc a : cp 21 : jp z, doNothing
    ld (cursor_pos), a
    call showCursor
    jp inputLoop

doNothing:
    call showCursor
    jp inputLoop

prepHeader:
    call clearScreen
    ld hl, header : call putStringZ
    ld b, 23, c, 0 : call gotoXY
    ld hl, footer : call putStringZ
    ld b, 1, c, 0 : call gotoXY
    ld a, 22 : call drawLine 
    xor a : jp drawLine

drawPage:
    call prepHeader
    
    ld b, 21
.l1
    push bc
    ld a, 21 : sub b 
    call printName
    pop bc
    djnz .l1
    call showCursor
    ret

; b - line count
findLine:
    ld hl, buffer
    ld a, b : and a : ret z
.l1
    ld a, (hl)
    or a : jr z, .l2
    inc hl 
    cp 10 : jr nz, .l1
    djnz .l1
    ret 
.l2
    ld hl, 0
    ret

findName:
    ld a, (hl)
    inc hl
    cp '"'
    ret z
    jr findName  

; a - Line number
printName:
    ld b, a
    call findLine
    ld a, l : or h : ret z
    call findName
    push hl
    ld a, ' ' : call putC
    pop hl
.l1
    ld a, (hl)
    cp '"'
    jp z, mvCR
    push hl
    call putC
    pop hl
    inc hl
    jr .l1


allDone db "All done!", 13, "Reboot and load some WiFi software", 0
enterpwd db "Enter WiFi password:", 0
initing db "Initializing your WiFi modem!", 13, 10, 0
header db "  WiFi configuration utility v.0.1 (c) Alexander Sharikhin", 13, 0 
footer db " Q/A - move cursor    Enter - select network for configuration", 0
getNetwork db 13, 10, "AT+CWLAP", 13, 10, 0

    include "screen64.asm"
    
    IFDEF AY
    include "ay-uart.asm"
    ENDIF

    IFDEF UNO
    include "uno-uart.asm"
    ENDIF

    include "utils.asm"
    include "ring.asm"
    include "wifi.asm"
    include "keyboard.asm"

    IFDEF PLUS3DOS
    include "p3dos.asm"
    ENDIF

    IFDEF ESXDOS
    include "esxdos.asm"
    ENDIF

buffer db 0
    IFDEF PLUS3DOS
    savebin "netman.bin", start, $ - start
    ENDIF
    
    IFDEF ESXDOS
    savetap "netman.tap", start
    ENDIF
