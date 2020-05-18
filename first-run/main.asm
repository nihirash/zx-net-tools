    DEVICE ZXSPECTRUM48
    org #8000
start:
    ld hl, hello : call putStringZ
    call sendSequence
    
    ld hl, done : call putStringZ

    xor a : ld hl, 0 :ld bc, 0
    ret

    include "data.asm"

sendSequence:
    di
    call uartBegin
    ld b, #ff : djnz $
    ld hl, dataSequence : ld bc, #bffd
    dup dataSize
    outi : ld bc, #bffd : nop
    edup
    ei
    ret

uartBegin:
    ld a, #07
    ld bc, #fffd
    out (c), a
    ld a, #fc
    ld b, #bf
    out (c), a ; Enable read mode
    
    ld a, #0e
    ld bc, #fffd
    out (c), a
    
    ld a, #fe
    ld b, #bf
    out (c), a ; Make CTS low
    ret

putStringZ
    ld a, (hl) 
    and a : ret z
    cp 13 : jr c, skip
    rst #10
skip:
    inc hl
    jr putStringZ

hello   db "Trying change speed of ESP-12", 13
        db "to 9600", 13, 0
    
done    db "Command sent", 13
        db "You should test it", 13, 0
    savetap "setSpeed.tap", start
    savebin "setSpeed.bin", start, $ - start