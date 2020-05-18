    include "spectranet/spectranet.inc"
    include "spectranet/sockdefs.inc"

; HL - domain
; BC - port
openTcp:
    display "Open tcp: ", $
    push BC
    ld de, ip_buffer
    ld ix, GETHOSTBYNAME
    call IXCALL

    jp c, tcpError
    ld c, SOCK_STREAM
    ld hl, SOCKET
    call HLCALL
    
    jp c, tcpError
    ld (sock_fd), a
    pop bc
    ld de, ip_buffer
    ld hl, CONNECT
    call HLCALL
    
    jp c, tcpError
    
    ld a, 1
    ld (connectionOpen), a
    ret

; DE - pointer to string
; BC - count
sendTcp:
    display "Send Tcp: ", $
    ld a, (sock_fd)
    ld hl, SEND
    call HLCALL
    jp c, tcpError
    ret

getPacket:
    ld hl, 0
    ld (bytes_avail), hl

    ld a, (sock_fd)
    ld hl, POLLFD
    call HLCALL
    ld a, c

    cp 2
    jp z, fin

    ld a, (sock_fd)
    ld de, output_buffer
    ld bc, 2048
    ld hl, RECV
    call HLCALL
    jp c, fin
    ld (bytes_avail), bc
    ret

fin: 
    xor a
    ld (connectionOpen), a

    ld a, (sock_fd)
    ld hl, CLOSE
    call HLCALL
    ret

tcpError:
    di
    halt

ip_buffer defs 4   
sock_fd db 0

output_buffer defs 2050
bytes_avail dw 0