    DEVICE ZXSPECTRUM48
    org #2000
Start:
        pop de
        ld (retAddr), de
        push de

        push hl
        ld hl, about
        call putStringZ
        
        pop hl
         
        ld a, l
        or h
        jr z, noArgs
        call loadArgs

        ld hl, initUart      : call putStringZ : call uartBegin
        ld hl, connecting    : call putStringZ : call initWifi
        ld hl, makingRequest : call putStringZ : ld hl, proto : call putStringZ 

        ld hl, proto : call httpGet

        ld hl, fout, b, FMODE_CREATE : call fopen
        ld (fpointer), a
        ld hl, downloading : call putStringZ
downloop:
        ld a, (fpointer)
        ld bc, (bytes_avail)
        ld hl, output_buffer
        call fwrite

        ld a, '.' : rst #10
        
        ld a, (fpointer)
        call fsync
        call getPacket
        jp downloop

loadArgs:
    ld de, url
aLp:    
    ld a,(hl)

    cp 13
    jr z, aE

    cp ':'
    jr z, aE

    cp ' '
    jr z, narg

    ld (de), a

    inc de
    inc hl
    jr aLp
aE:
    ld a, 0
    ld (de), a
    ret
narg:
    ld a, #d
    ld (de), a

    inc de
    ld a, 0
    ld (de), a

    inc hl
    ld de, fout
    jr aLp

noArgs: 
    ld hl, usage
    call putStringZ
    ret

closed_callback
    ld a, (fpointer)
    call fclose

    ld hl,done
    call putStringZ

    ld de, (retAddr)
    push de    
	ret	

; A - char
putC:
    rst #10
    ret

; HL - string
putStringZ:
    ld a, (hl)
    and a
    ret z
    push hl
    call putC
    pop hl
    inc hl
    jr putStringZ

uartWriteStringZ:
    ld a, (hl)
    and a : ret z
    push hl
    call uartWriteByte
    pop hl
    inc hl 
    jr uartWriteStringZ

about:      defb 'wGet v.0.3 (c) 2020 Nihirash', 13, 0
usage:      defb 'Usage: .wget <url> <outputfile>', 13, 0
initUart    defb "Initializing UART", 13, 0
connecting  defb "Connecting to WiFi", 13, 0
makingRequest defb "Making request: ", 13, 0
downloading defb 'Downloading', 0
done:       defb 13, 'File saved', 13, 0
proto       db "http://"
url         defs 255 ; 0xd ending is important! Be carefull!
fout        defs 80
test_params defb '1 2 3',0
fpointer    defb 0
retAddr     defw 0

conclosed db 13, 13, "Connection closed", 0
    IFDEF UNO
    include "uno-uart.asm"
    ENDIF

    IFDEF AY
    include "ay-uart.asm"
    ENDIF

    include "wifi.asm"
    include "ring.asm"
    include "http.asm"
    include "esxdos.asm"
output_buffer EQU $
    SAVEBIN "WGET", Start, $ - Start 
