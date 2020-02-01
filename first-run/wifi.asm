; Initialize WiFi chip and connect to WiFi
initWifi:

    ld bc, #ff
intLp1:
    push bc
    ld b, #ff
    djnz $
    pop bc
    djnz intLp1

    ld hl, cmd_plus
    call uartWriteStringZ
    ld b,#ff
wlp:
    push bc
    ld b, #ff
    djnz $
    pop bc
    djnz wlp

    ld hl, cmd_rst
    call uartWriteStringZ
rstLp:
    call uartReadBlocking
    call pushRing
    ld hl, response_rdy
    call searchRing
    cp 1
    jr nz, rstLp     

    ld hl, cmd_at   ; Disable ECHO. BTW Basic UART test
    call okErrCmd
    and 1
    jr z, errInit
    
    ld hl, cmd_cwqap ; Lets disconnect from last AP
    call okErrCmd
    and 1
    jr z, errInit

    ld hl, cmd_cmux ; Single connection mode 
    call okErrCmd
    and 1
    jr z, errInit

    ld hl, cmd_inf_off  ; FTP enables this info? We doesn't need it :-)
    call okErrCmd
    and 1
    jr z, errInit
    
    ld hl, log_ok
    call putStringZ

    ret
errInit
    ld hl, log_err
    call putStringZ
    jr $


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
okErrOk
    ld a, 1
    ret
okErrErr
    ld a, 0
    ret

cmd_plus    defb "+++", 0
cmd_rst     defb "AT+RST",13, 10, 0
cmd_at      defb "ATE0", 13, 10, 0                  ; Disable echo - less to parse
cmd_mode    defb "AT+CWMODE_DEF=1",13,10,0	        ; Client mode
cmd_cmux    defb "AT+CIPMUX=0",13,10,0              ; Single connection mode
cmd_cwqap   defb "AT+CWQAP",13,10,0		            ; Disconnect from AP
cmd_inf_off defb "AT+CIPDINFO=0",13,10,0            ; doesn't send me info about remote port and ip


response_rdy    defb 'ready', 0
response_ok     defb 'OK', 13, 10, 0      ; Sucessful operation
response_err    defb 13,10,'ERROR',13,10,0      ; Failed operation
response_fail   defb 13,10,'FAIL',13,10,0       ; Failed connection to WiFi. For us same as ERROR

log_ok  defb 'WiFi chip initialized!', 13, 0

ssid        defs 80
pass        defs 80

bytes_avail	  defw 0
sbyte_buff     defb 0, 0 

send_prompt defb ">",0

; WiFi configuration
conf_file defb "/sys/config/iw.cfg",0