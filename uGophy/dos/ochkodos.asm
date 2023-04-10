
    module Dos
page = 1
	include "ff.equ"

init:
    di
    ld a, page : call changeBank
    ld hl, bin, de, #c000 : call sauk
mount:    
    ld l,1			; Check for valid
	push hl
	ld bc,drpath_zsd : ld de,ffs		
	call FF_MOUNT
	pop hl
	or a
    jp nz, error
    ei
    sub a : call changeBank
    ret

; DE - ASCIZ path
cwd:
    ld a, page : call changeBank
    call FF_CHDIR
    push af
    sub a : call changeBank
    pop af
    ret

; DE - ASCIZ path
mkdir:
    ld a, page : call changeBank
    call FF_MKDIR
    push af
    sub a : call changeBank
    pop af
    ret

; L - file mode:
; BC - filename
fopen:
    push bc : ld a, page : call changeBank : pop bc

    push hl
    ld de, file
    call FF_OPEN
    pop hl

    push af : sub a : call changeBank : pop af
    ret

; BC - buffer
; DE - buffer size
fread:
    push bc : ld a, page : call changeBank : pop bc

    ld hl, rwres
    push hl
    push de
    ld de, file
    call FF_READ
    pop hl
    pop hl
    ret

; BC - buffer
; DE - buffer size
fwrite:
    push bc : ld a, page : call changeBank : pop bc

    ld hl, rwres
    push hl
    push de
    ld de, file
    call FF_WRITE
    pop hl
    pop hl

    push af : sub a : call changeBank : pop af
    ret

fclose:
    push bc : ld a, page : call changeBank : pop bc

    ld de, file
    call FF_CLOSE

    push af : sub a : call changeBank : pop af
    ret

error:
    add '0'
    call putC
    ld hl, .msg : call putStringZ
    jr $
.msg db " - can't init SD Card or FAT!",13,"Computer halted!",0


ffs			defs	FATFS_SIZE
file		defs	FIL_SIZE
rwres		defw	0
drpath_zsd	defb 	'0:',0	;путь девайса для монтирования. В данном случае Z-SD
dir			defs	DIR_SIZE
finfo		FILINFO

    IFNDEF NOIMAGE
bin: 
	incbin "fatfs.skv"
bin_size = $ - bin
    include "decompressor.asm"
        
    DISPLAY "fatfs size: ", $ - bin
    display "FAT FS ENDS: ", $
    ENDIF
    
    endmodule
