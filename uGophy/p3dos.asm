DOS_READ      = #0112
DOS_WRITE     = #115
DOS_OPEN      = #0106
DOS_CLOSE     = #0109
DOS_MOTOR_OFF = #019C
DOS_SET_1346  = #013F

CMR0  = #7FFD

; +3DOS constants
OPEN_ACTION_ERROR_EXISTS = 0
OPEN_ACTION_POSITION_TO_DATA = 1
OPEN_ACTION_POSITION_TO_HEADER = 2
OPEN_ACTION_MAKE_BACKUP = 3
OPEN_ACTION_OVERWRITE = 4

CREATE_ACTION_DONTCREATE = 0
CREATE_ACTION_POINT_TO_DATA = 1
CREATE_ACTION_POINT_TO_HEADER = 2

FILE_TYPE_BASIC = 0
FILE_TYPE_NUM_ARRAY = 1
FILE_TYPE_CHR_ARRAY = 2
FILE_TYPE_BYTES = 3

ACCESS_MODE_EXCLUSIVE_READ = 1
ACCESS_MODE_EXCLUSIVE_WRITE = 2
ACCESS_MODE_EXCLUSIVE_READ_WRITE = 3
ACCESS_MODE_SHARED = 5

FMODE_CREATE = 0

initDos:
    ld ix, DOS_SET_1346  : ld hl,0 : ld d,h : ld e,d : call plus3dos ; disable RAM DISK
    ret

; C - access mode
; D - Create action
; E - Open action
; HL - filename
fopen:
    ld b, 1
    push hl
.l1 
    inc hl ; Anyway filename more than one symbol
    ld a, (hl)
    and a 
    jr nz, .l1
    ld a, #ff : ld (hl), a
    pop hl
    ld ix, DOS_OPEN : call plus3dos
    ret c
    jp error
    
; C - page
; DE - byte count
; HL - Address
fread:
    ld b, 1 : ld ix, DOS_READ
    jp plus3dos
     
; C - page
; DE - Bytes
; HL - Buffer
fwrite: 
    ld b, 1 : ld ix, DOS_WRITE
    jp plus3dos
    
fclose:
    ld b, 1 : ld ix, DOS_CLOSE
    call plus3dos 
    ld ix, DOS_MOTOR_OFF 
    jp plus3dos 

error:
    ld a, 2
    out (254), a
    ld hl, dos_error
    jp putStringZ
    

setDOS: 
    di
	push	bc
	push	af
	ld	bc, CMR0
	ld	a,(bankm)
	res	4,a
	or	7
	ld	(bankm),a
	out	(c),a
	pop	af
	pop	bc
	ret

plus3dos:
	call	setDOS
	ld	(adds+1),ix
adds:	call	0
setBASIC:
	di
	push	af
	ld	bc, CMR0
	ld	a,(bankm)
	set	4,a
	and	#0f8
	ld	(bankm),a
	out	(c),a
	pop	af
	ret

dos_error db 13, "DOS OPERATION ERROR!", 13, 0