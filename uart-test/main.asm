    ORG 32768
    DEVICE ZXSPECTRUM48
start:
    call uartBegin
    ld hl, test
.loop
    ld a, (hl)
    and a : jr z, .read
    push hl
    call uartWriteByte
    pop hl
    inc hl
    jr .loop
.read
    call uartReadBlocking
    rst #10
    jr .read
test    db "AT+RST", 13, 10, 0
    include "ay-uart.asm"
    savetap "test.tap", start