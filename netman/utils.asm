bankm	equ 23388

; A - memory bank
changeBank:
    ld bc, #7ffd : or #18 : out (c), a : ld (bankm), a
    ret

; Pushes to UART zero-terminated string
; HL - string poiner
uartWriteStringZ:
    ld a, (hl) : and a : ret z

    push hl : call uartWriteByte : pop hl
    
    inc hl
    jp uartWriteStringZ

; Print zero-terminated string
; HL - string pointer
putStringZ:
printZ64:
	ld a,(hl) : and a : ret z
	
    push hl : call putC : pop hl

	inc hl
	jr printZ64


printL64:
	ld a, (hl)
	
	and a : ret z
	cp #0A : ret z
	cp #0D : ret z

	push hl : call putC : pop hl
    
    inc hl
	jr printL64

; HL - string
; Return: bc - len
getStringLength:
    ld bc, 0
strLnLp
    ld a, (hl) : and a : ret z
    inc bc 
    inc hl
    jr strLnLp

SkipWhitespace:
	ld a, (hl) 
    
    cp ' ' : ret nz 
    
    inc hl
    jr SkipWhitespace

findEnd:
    ld a,(hl)

    and a : ret z
    
    inc hl
    jr findEnd
