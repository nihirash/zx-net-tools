ZIFI_CMD_REG = #C7EF
ZIFI_ERR_REG = #C7EF
ZIFI_DATA_REG = #BFEF
ZIFI_FIFO_IN = #C0EF
ZIFI_FIFO_OUT = #C1EF

ZIFI_CMD_CLEAR_FIFO_IN = #01
ZIFI_CMD_CLEAR_FIFO_OUT = #02
ZIFI_CMD_CLEAR_FIFO_BOTH = #03
ZIFI_CMD_API_DISABLE = #F0
ZIFI_CMD_API_ENABLE = #F1
ZIFI_CMD_API_VERSION = #FF

; Enable UART
; Cleaning all flags by sending api enable command and clear command to both fifo
; Wastes AF and BC
uartBegin:
    ld bc, ZIFI_CMD_REG : ld a, ZIFI_CMD_API_ENABLE : out (c), a
    ld bc, ZIFI_CMD_REG : ld a, ZIFI_CMD_CLEAR_FIFO_BOTH : out (c), a
    ld b, #ff
.loop
    push bc
    call uartRead
    pop bc
    djnz .loop    

    ret

; Blocking read one byte
uartReadBlocking:
    call uartRead
    push af : ld a, 1 : and b : jr nz, urb : pop af
    jp uartReadBlocking
urb: 
    pop af
    ret

; Write single byte to UART
; A - byte to write
; BC will be wasted
; TODO: check input fifo is not full
uartWriteByte:
    push af
    ld bc, ZIFI_DATA_REG : out (c), a
    pop af
    ret

; Read byte from UART
; A: byte
; B:
;     1 - Was read
;     0 - Nothing to read
uartRead:
    ld bc, ZIFI_FIFO_IN : in a, (c)
    jr nz, retReadByte

    ld b, 0
    ret

retReadByte:
    ld bc, ZIFI_DATA_REG : in a, (c)

    ld b, 1
    ret

