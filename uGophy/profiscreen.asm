; Profi (512x240) screen routines
;
; Public definitions:
; clearScreen
; showCursor
; hideCursor
; putC
; gotoXY

SCREEN_ROWS = 28

showCursor:
hideCursor:
    call showType
    ld a, (cursor_pos)
    ld d, a
inverseLine: 
	ld e, 0
	ld b, 64
ilp
	push bc
	push de
	call findAddr
    ld a, 6
    ld b, #80
    call changeBank
	
	ld b, 8
iCLP:	
	ld a, (de)
	xor #ff
	ld (de), a
	inc d
	djnz iCLP
	pop de
	inc e
	pop bc
	djnz ilp

    ;xor a
    ;call changeBank
	
    ret

gotoXY:
    ld (coords), bc
    ret

mvCR:
	ld hl, (coords)
	inc h
	ld l, 0
	ld (coords), hl
	cp 24
	ret c
	ld hl, 0
	ld (coords), hl
	ret	

; A - char
putC:
	cp 13
	jr z, mvCR

	sub 32
    ld b, a
    
    ld de, (coords)
    ld a, e
    cp 64
    ret nc

	push bc

    ld a, 6
    call changeBank

	call findAddr
	pop af
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	ld bc, font
	add hl, bc
	ld b, 8
pLp:
	ld a, (HL)
	ld (DE), A
	inc hl
	inc d
	djnz pLp
	ld hl, (coords)
	inc l
	ld (coords), hl
	ret

; D - Y
; E - X
; OUT: de - coords
findAddr:
    ld a, e
    srl a
    ld e, a
    ld hl, #8000
    jr c, fa1
    ld hl, #A000
fa1:		   
    LD A,D
    AND 7
    RRCA
    RRCA
    RRCA
    OR E
    LD E,A
    LD A,D
    AND 24
    OR 64
    LD D,A
    ADD hl, de
    ex hl, de
    ret

clearScreen:

    ld a, 6
    call changeBank
    xor a
    call changeBankHiProfi

    ld a, #ff ; black border (inversed on profi screen)
    out (#fe), a

    di
    ld	hl,0
    ld	d,h
    ld	e,h
    ld	b,h
    ld	c,b
    add	hl,sp
    ld	sp,#c000 + 8192
clgloop
	push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    djnz	clgloop

    ld	b,c
    ld	sp,#e000 + 8192
clgloop2:
    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    push	de
    push	de
    push	de
    push	de

    djnz	clgloop2

    ld	sp,hl

; set profi attributes white ink / black screen

    ; RAM 3A = 111 dffd, 010 7ffd
    ld a, 2
    call changeBank
    ld a, 7
    call changeBankHiProfi

    ld a, #47 ; white bright on black
    ld hl, #c000
    ld b, 128
claloop1:
    ld c, 64
claloop2:
    ld (hl),a
    inc hl 
    dec c 
    jp nz, claloop2
    dec b 
    jp nz, claloop1

    ld a, #47
    ld hl, #e000 
    ld b, 128
claloop3:
    ld c, 64
claloop4:
    ld (hl), a
    inc hl
    dec c 
    jp nz, claloop4
    dec b
    jp nz, claloop3

    xor a
    call changeBank
    xor a
    call changeBankHiProfi
    
    ei
    ret

coords dw 0
attr_screen db 0 ; just for compatibility
; Using ZX-Spectrum font - 2K economy
font equ #3D00