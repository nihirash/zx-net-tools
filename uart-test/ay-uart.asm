    DISPLAY "UART BEGINS AT ", $
; Enable UART
; Cleaning all flags by reading UART regs
; Wastes AF and BC
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
    ld a, #fb
    ld b, #bf
    out (c), a
    ld b, #ff
    ei 
.flush
    halt
    djnz .flush
    ret

; Blocking read one byte
uartReadBlocking:
    call uartRead
    push af : jr c, urb : pop af
    jp uartReadBlocking
urb: 
    pop af
    ret

readSilient:
    call uartRead
    ret c
    jr readSilient


uartWriteByte:
    push af
    call putC
    
    ld c, #fd ; prepare port addresses
    ld d, #ff
    ld e, #bf
    ld b, d
    
    ld a, #0e
    out (c), a ; Select AY's PORT A

    ld hl, (_baud)
    ld de, #0002
    or a
    sbc hl, de
    ex hl, de

    pop af
    cpl
    scf
    ld b, #0b ; Numbers of bits - 1 start, 8 data, 2 stop

    di ; Hard timing starts
transmitBit:
    push bc
    push af

    ld a, #fe
    ld h, d
    ld l, e
    ld bc, #bffd
    jp nc, transmitOne
; Transmit Zero:
    and #f7
    out (c), a
    jr transmitNext
transmitOne:
    or 8
    out (c), a
    jr transmitNext

transmitNext:
    dec hl
    ld a, h 
    or l
    jr nz, transmitNext
    
    nop
    nop
    nop

    pop af
    pop bc
    or a
    rra 
    djnz transmitBit
    ei
    ret

uartRead:
    call _uartRead
    ret nc
    push af
    call putC
    pop af 
    scf
    ret

_uartRead:
    ld hl, _testByte
    ld a, (hl)
    and a
    jr z, testSecond
    inc hl
    ld a, (hl)
    scf 
    ret
testSecond:
    ld hl, _isSecondByteAvail
    ld a, (hl)
    and a 
    jr z, startReadByte
    ld (hl), 0
    inc hl
    ld a, (hl)
    scf
    ret
startReadByte:
    di
    xor a
    exx
    ld de, (_baud) 
    ld hl, (_baud)
    srl h 
    rr l  ; HL=_baud/2
    or a 
    ld b, #FA ; Wait look length
    exx
    ld c, #fd
    ld d, #ff
    ld e, #bf
    ld b, d 
    ld a, #0e
    out (c), a
    in a, (c)
    or #f0      ; Input lines is 1
    and #fb     ; CTS force to 0
    ld b, e     ; B = #BF
    out (c), a  ; Make CTS high
    ld h, a

waitStartBit:
    ld b, d
    in a, (c)
    and #80
    jr z, startBitFound
readTimeOut:
    exx
    dec b 
    exx
    jr nz, waitStartBit
    xor a
    push af
    jr readFinish
startBitFound:
    in a, (c)
    and #80
    jr nz, readTimeOut

    in a, (c)
    and #80
    jr nz, readTimeOut
    ;; Start bit found!
    
    exx
    ld bc, #fffd
    ld a, #80
    ex af, af
readTune:
    add hl, de ; HL = 1.5 * _baud
    nop
    nop
    nop
    nop ; Fine tuning delay

bdDelay:
    dec hl
    ld a, h
    or l 
    jr nz, bdDelay

    in a, (c)
    and #80
    jp z, zeroReceived
; One received:       
    ex af, af
    scf
    rra 
    jr c, receivedByte
    ex af, af
    jp readTune
zeroReceived:
    ex af, af
    or a 
    RRA 
    jr c, receivedByte
    ex af, af
    jp readTune
receivedByte:
    scf
    push af
    exx
readFinish: 
    ld a, h
    or #04 
    ld b, e
    out (c), a
    
    exx 
    ld h, d
    ld l, e 

    ld bc, #0007
    or a 
    sbc hl, bc

delayForStopBit:
    dec hl
    ld a, h
    or l
    jr nz, delayForStopBit

    ld bc, #fffd
    add hl, de
    add hl, de
    add hl, de

waitStartBitSecondByte:
    in a, (c)
    and #80
    jr z, secondStartBitFound
    dec hl
    ld a, h
    or l
    jr nz, waitStartBitSecondByte
    ; No second byte
    pop af
    ei
    ret

secondStartBitFound:
    in a, (c)
    and #80
    jr nz, waitStartBitSecondByte
    ld h, d
    ld l, e 
    ld bc, #0002
    srl h
    rr l
    or a 
    sbc hl, bc
    ld bc, #fffd
    ld a, #80
    ex af, af
secondByteTune:
    nop
    nop
    nop
    nop
    add hl, de

secondDelay:
    dec hl
    ld a, h
    or l
    jr nz, secondDelay

    in a, (c)
    and #80
    jr z, secondZeroReceived
; Second 1 received    
    ex af, af
    scf 
    rra 
    jr c, secondByteFinished
    ex af, af
    jp secondByteTune

secondZeroReceived:
    ex af, af
    or a 
    rra 
    jr c, secondByteFinished
    ex af, af
    jp secondByteTune
secondByteFinished:
    ld hl, _isSecondByteAvail
    ld (hl), 1
    inc hl 
    ld (hl), a
    pop af 
    ei 
    ret
dataSequence:

    db  #f6,  #fe,  #f6,  #fe,  #fe,  #f6,  #f6,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #fe,  #f6,  #fe,  #f6,  #f6,  #f6,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #f6,  #f6,  #f6,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #fe,  #f6,  #fe,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #fe,  #fe,  #f6,  #fe,  #f6,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #fe,  #f6,  #fe,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #f6,  #f6,  #f6,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #f6,  #fe,  #f6,  #f6,  #fe,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #fe,  #f6,  #fe,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #fe,  #fe,  #fe,  #fe,  #fe,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #fe,  #f6,  #f6,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #fe,  #f6,  #f6,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #f6,  #fe,  #fe,  #f6,  #f6,  #f6,  #fe,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #fe,  #fe,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #f6,  #fe,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #fe,  #fe,  #f6,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #f6,  #fe,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #f6,  #fe,  #fe,  #f6,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #fe,  #f6,  #f6,  #fe,  #fe,  #f6,  #f6,  #fe
    db  #f6,  #fe,  #f6,  #fe,  #fe,  #f6,  #f6,  #f6,  #f6,  #fe
    db  #f6,  #f6,  #fe,  #f6,  #fe,  #f6,  #f6,  #f6,  #f6,  #fe
dataSize = $ - dataSequence
; Total bytes 28 

setSpeed:
    ld hl, dataSequence : ld bc, #bffd
    
    dup dataSize
    outi : ld bc, #bffd : nop
    edup
    ret


_baud dw 11 ; 54 - 2400 --- 25 - 4800 --- 11 - 9600
_isSecondByteAvail dw #0
_testByte dw #0
