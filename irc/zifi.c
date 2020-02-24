#include "zifi.h"
int is_connected = 0;

void initWifi()
{
    __asm
        call initWifi
    __endasm;
}


void errInit()
{
  cprintf("Cannot init Wifi!");
  for (;;);
}

void errConnect()
{
  cprintf("Cannot connect to WiFi");
  for (;;);
}

void closed_callback()
{
  cprintf("Connection closed");
  for(;;);
}

void checkNoWiFiConfig()
{
    for (;&ssid[0] == 0;) {
        printf("\nWifi SSID:");
        cgets(&ssid);
        if (&ssid[0]) {
            printf("Wifi password(may keep empty): ");
            cgets(&wpass);
        }
    }
}


char openTcp(char *host, char *port) __stdc
{
    __asm 
        ld hl, 2
        add hl, sp

        ld e, (hl)
        inc hl
        ld d, (hl)
        inc hl

        ld c, (hl)
        inc hl
        ld b, (hl)
        push bc
        pop hl

        call startTcp
        ld h, 0
        ld l, a
    __endasm;
}

char isAvail() __z88dk_sdccdecl
{
    __asm
        call uartAvail
	    ld hl, 0
        jr nc, iaa
	    ld l, 1
    iaa: 
    __endasm;
}

char sendByte(char c) __stdc
{
    __asm
        ld hl, 2
        add hl, sp
        ld a, (hl)
        call uartWriteByte
        ld h, 0
        ld l, 1
    __endasm;
}

char getByte() __stdc
{
    __asm
        call uartRead
        ld h, 0
        ld l, a
    __endasm;
}

__asm


; Enable UART
; Cleaning all flags by reading UART regs
; Wastes AF and BC
uartBegin:
    ld a, $07
    ld bc, $fffd
    out (c), a
    ld a, $fc
    ld b, $bf
    out (c), a ; Enable read mode
    
    ld a, $0e
    ld bc, $fffd
    out (c), a
    ld a, $fe
    ld b, $bf
    out (c), a ; Make CTS low
    ret

; Pushes to UART zero-terminated string
; HL - string poiner
uartWriteStringZ:
    ld a, (hl)
    and a
    ret z
    push hl
    call uartWriteByte
    pop hl
    inc hl 
    jr uartWriteStringZ

; Blocking read one byte
uartReadBlocking:
    call uartRead
    push af 
    jr c, urb
    pop af
    jp uartReadBlocking
urb: 
    pop af
    ret

; Write single byte to UART
; A - byte to write
; BC will be wasted
uartWriteByte:
    push af
    
    ld c, $fd ; prepare port addresses
    ld d, $ff
    ld e, $bf
    ld b, d
    
    ld a, $0e
    out (c), a ; Select AYs PORT A

    ld hl, 11
    ld de, $0002
    or a
    sbc hl, de
    ex de, hl

    pop af
    cpl
    scf
    ld b, $0b ; Numbers of bits - 1 start, 8 data, 2 stop

    di ; Hard timing starts
transmitBit:
    push bc
    push af

    ld a, $fe
    ld h, d
    ld l, e
    ld bc, $bffd
    jp nc, transmitOne
; Transmit Zero:
    and $f7
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

; Is data avail in UART
; C - Data Presents
; NC - Data absent
uartAvail:
    ld a, (testSecond)
    and a
    jr nz, byteAvail
    ld a, (_isSecondByteAvail)
    and a
    jr nz, byteAvail
    call uartRead
    ret nc
    ld hl, testSecond
    ld (hl), 1
    inc hl
    ld (hl), a
    ld a, 1
    scf
    ret
byteAvail:
    ld a, 1
    scf
    ret 

; Read byte from UART
; A: byte
; B:
;     1 - Was read
;     0 - Nothing to read
uartRead:
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
    ld de, 11
    ld hl, 11
    srl h 
    rr l  ; HL=_baud/2
    or a 
    ld b, $FA ; Wait look length
    exx
    ld c, $fd
    ld d, $ff
    ld e, $bf
    ld b, d 
    ld a, $0e
    out (c), a
    in a, (c)
    or $f0      ; Input lines is 1
    and $fb     ; CTS force to 0
    ld b, e     ; B = #BF
    out (c), a  ; Make CTS high
    ld h, a

waitStartBit:
    ld b, d
    in a, (c)
    and $80
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
    and $80
    jr nz, readTimeOut

    in a, (c)
    and $80
    jr nz, readTimeOut
    ;; Start bit found!
    
    exx
    ld bc, $fffd
    ld a, $80
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
    and $80
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
    or $04 
    ld b, e
    out (c), a
    
    exx 
    ld h, d
    ld l, e 

    ld bc, $0007
    or a 
    sbc hl, bc

delayForStopBit:
    dec hl
    ld a, h
    or l
    jr nz, delayForStopBit

    ld bc, $fffd
    add hl, de
    add hl, de
    add hl, de

waitStartBitSecondByte:
    in a, (c)
    and $80
    jr z, secondStartBitFound
    dec hl
    ld a, h
    or l
    jr nz, waitStartBitSecondByte
    ; No second byte
    pop af
    
    ret

secondStartBitFound:
    in a, (c)
    and $80
    jr nz, waitStartBitSecondByte
    ld h, d
    ld l, e 
    ld bc, $0002
    srl h
    rr l
    or a 
    sbc hl, bc
    ld bc, $fffd
    ld a, $80
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
    and $80
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
     
    ret

; Returns: 
;  A - current drive
getDefaultDrive:
    ld a, 0
    rst $8
    defb ESX_GETSETDRV
    ret

; Opens file on default drive
; B - File mode
; HL - File name
; Returns:
;  A - file stream id
fopen:
    push bc
    push hl
    call getDefaultDrive
    pop ix
    pop bc
    rst $8
    defb ESX_FOPEN
    ret

; A - file stream id
fclose:
    rst $8
    defb ESX_FCLOSE
    ret

; A - file stream id
; BC - length
; HL - buffer
; Returns
;  BC - length(how much was actually read) 
fread:
    push hl
    pop ix
    rst #8
    defb ESX_FREAD
    ret

; A - file stream id
; BC - length
; HL - buffer
; Returns:
;   BC - actually written bytes
fwrite:
    push hl
    pop ix
    rst #8
    defb ESX_FWRITE
    ret
    
; A - file stream id
fsync:
    rst #8
    defb ESX_FSYNC
    ret

; Initialize WiFi chip and connect to WiFi
initWifi:
    call uartBegin
    call loadWiFiConfig
    
    ld hl, cmd_plus
    call uartWriteStringZ
    halt
    halt
    halt
    ld hl, cmd_rst
    call uartWriteStringZ
rstLp:
    call uartReadBlocking
    call pushRing

    ld hl, response_rdy
    call searchRing
    cp 1
    jp nz, rstLp

    ld hl, cmd_at   ; Disable ECHO. BTW Basic UART test
    call okErrCmd
    and 1
    jp z, _errInit

    ld hl, cmd_mode
    call okErrCmd
    and 1
    jp z, _errInit
    
    ld hl, cmd_cwqap ; Lets disconnect from last AP
    call okErrCmd
    and 1
    jp z, _errInit

    ld hl, cmd_cmux ; Single connection mode 
    call okErrCmd
    and 1
    jp z, _errInit

    ld hl, cmd_inf_off  ; FTP enables this info? We doesnt need it :-)
    call okErrCmd
    and 1
    jp z, _errInit

    ld hl, cmd_cipmode
    call okErrCmd
    and 1
    jp z, _errInit

    ld hl, cmd_cwjap1 ; Access Point connection
    call uartWriteStringZ
    ld hl, _ssid
    call uartWriteStringZ
    ld hl, cmd_cwjap2
    call uartWriteStringZ
    ld hl, _wpass
    call uartWriteStringZ
    ld hl, cmd_cwjap3
    call okErrCmd
    and 1
    jp z, _errConnect
    
    ret


; Send AT-command and wait for result. 
; HL - Z-terminated AT-command(with CR/LF)
; A:
;    1 - Success
;    0 - Failed
okErrCmd: 
    call uartWriteStringZ
okErrCmdLp:
    call uartReadBlocking
    call pushRing
    
    ld hl, response_ok
    call searchRing
    cp 1
    jr z, okErrOk
    
    ld hl, response_err
    call searchRing
    cp 1
    jr z, okErrErr

    ld hl, response_fail
    call searchRing
    cp 1
    jr z, okErrErr


    jp okErrCmdLp
okErrOk:
    ld a, 1
    ret
okErrErr:
    ld a, 0
    ret


; HL - z-string to hostname or ip
; DE - z-string to port
startTcp:
    push de
    push hl
    ld hl, cmd_open1
    call uartWriteStringZ
    pop hl
    call uartWriteStringZ
    ld hl, cmd_open2
    call uartWriteStringZ
    pop hl
    call uartWriteStringZ
    ld hl, cmd_open3
    call okErrCmd

    ld hl, cmd_send_begin
    call okErrCmd

spt:
    call uartReadBlocking
    call pushRing

    ld hl, send_prompt
    call searchRing
    cp 1
    jr nz, spt

    ret

loadWiFiConfig:
    ld b, FMODE_READ
    ld hl, conf_file
    call fopen

    push af
    ld hl, _ssid
    ld bc, 80
    call fread
    pop af
    push af
    ld hl, _wpass
    ld bc, 80
    call fread
    pop af
    call fclose
    jp _checkNoWiFiConfig

    ; Pushes A to ring buffer
pushRing:
    push af
    ld b, 32
    ld hl, ring_buffer + 1
    ld de, ring_buffer 
ringL:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    djnz ringL
    pop af
    ld hl, ring_buffer + 31
    ld (hl), a
    ret

; HL - Compare string(null terminated)
; A - 0 NOT Found 
;     1 Found
searchRing:
    ld b, 0
    push hl
serlp: 
    ld a, (hl)
    inc hl
    inc b
    and a
    jp nz, serlp
    dec b
    pop hl
    push bc
    push hl
SRWork:
    pop hl
    ld de, ring_buffer + 32
srcLp:   
    dec de
    djnz srcLp
    pop bc
ringCmpLp:    
    push bc
    push af
    ld a, (de)
    ld b, a
    pop af
    ld a, (hl)
    cp b
    pop bc
    ld a, 0
    ret nz  
    inc de
    inc hl
    djnz ringCmpLp
    ld a, 1
    ret
    
ring_buffer: defs 32
cmd_plus:    defb "+++",0
cmd_rst:     defb "AT+RST\r\n",0 
cmd_at:      defb "ATE0\r\n", 0                  ; Disable echo - less to parse
cmd_mode:    defb "AT+CWMODE_DEF=1\r\n",0	        ; Client mode
cmd_cmux:    defb "AT+CIPMUX=0\r\n",0              ; Single connection mode
cmd_cwqap:   defb "AT+CWQAP\r\n",0		            ; Disconnect from AP
cmd_inf_off: defb "AT+CIPDINFO=0\r\n",0            ; doesnt send me info about remote port and ip
cmd_cipmode:    defb "AT+CIPMODE=1\r\n", 0             ; DIRECT MODE

cmd_send_begin: defb "AT+CIPSEND\r\n", 0

cmd_cwjap1:  defb  "AT+CWJAP_CUR=\"",0        ;Connect to AP. Send this -> _ssid
cmd_cwjap2:  defb "\",\"",0                     ; -> This -> _wpass
cmd_cwjap3:  defb '"', 13, 10, 0                 ; -> And this

cmd_open1:   defb "AT+CIPSTART=\"TCP\",\"", 0
cmd_open2:   defb "\",", 0
cmd_open3:   defb "\r\n", 0

response_rdy:    defb "ready", 0
response_ok:     defb "OK",13, 10, 0      ; Sucessful operation
response_err:    defb "ERROR",13,10,0      ; Failed operation
response_fail:   defb "FAIL",13,10,0       ; Failed connection to WiFi. For us same as ERROR

_ssid:        defs 80
_wpass:        defs 80

send_prompt: defb ">",0

; WiFi configuration
conf_file: defb "/sys/config/iw.cfg",0

_isSecondByteAvail: defb 0, 0
_testByte: defb 0, 0


__endasm;