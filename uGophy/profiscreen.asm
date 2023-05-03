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

    ld a, 6 : call changeBank ; RAM06
    xor a : call changeBankHiProfi
    ld a, #ff : out (#fe), a ; black border (inversed on profi screen)

    di
    ld hl,0 : ld d,h : ld e,h : ld b,h :ld c,b
    add	hl,sp
    ld	sp, 0 ; #c000 + 16384 ; profi pixels (both banks)
clgloop
    DUP 32
	push	de
    EDUP
    djnz	clgloop ; 256 times
    ld	sp,hl

    ; RAM 3A = 111 dffd, 010 7ffd
    ld a, 2 : call changeBank
    ld a, 7 :call changeBankHiProfi

    ld hl,0 : ld d,#47 : ld e,#47 : ld b,h :ld c,b ; #47 = white on black
    add	hl,sp
    ld sp, 0 ; #c000 + 16384 ; profi attrs (both banks)
claloop
    DUP 32
	push	de
    EDUP
    djnz	claloop ; 256 times
    ld	sp,hl

    xor a : call changeBank
    xor a : call changeBankHiProfi
    
    ei
    ret

coords dw 0
attr_screen db 0 ; just for compatibility
; Using ZX-Spectrum font - 2K economy
font equ #3D00