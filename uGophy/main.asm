;; (c) 2019 Alexander Sharikhin
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

    DEVICE ZXSPECTRUM128
    org 24100
Start: 
    di
    res 4, (iy+1)
    IFNDEF ZX48
stack_pointer = #5aff
    call checkHighMem : jp nz, noMem
    
    xor a : out (#fe), a : call changeBank
    ld de, #4000 : ld bc, eop - player : ld hl, player : ldir
    ELSE
    jp zx48start
    ds 128
stack_pointer = $ - 1
    ENDIF
zx48start:
    ld sp, stack_pointer
    xor a : ld (#5c6a), a  ; Thank you, Mario Prato, for feedback
    ei

    call renderHeader
    
    IFDEF PLUS3DOS
    call initDos
    ENDIF
    
    IFNDEF SPECTRANET
    call initWifi
    ENDIF
    
    call wSec

    ld de, path : ld hl, server : ld bc, port : call openPage

    jp showPage
    IFNDEF ZX48
noMem:
    ld hl, no128k
nmLp:
    push hl
    ld a, (hl)
    and a : jr z, $
    rst #10
    pop hl
    inc hl
    jp nmLp
    ENDIF


wSec: ei : ld b, 50
wsLp  halt : djnz wsLp
    IFDEF TIMEXSCR
    include "tscreen.asm"
    ELSE
    include "screen64.asm"
    ENDIF
    include "keyboard.asm"
    include "utils.asm"
    include "gopher.asm"
    include "render.asm"
    include "textrender.asm"
    include "ring.asm"

    IFDEF PLUS3DOS
    include "p3dos.asm"
    ENDIF

    IFDEF ESXDOS
    include "esxdos.asm"
    ENDIF

    IFDEF AY
    include "wifi.asm"
    include "ay-uart.asm"
    ENDIF
    
    IFDEF UNO
    include "uno-uart.asm"
    include "wifi.asm"
    ENDIF

    IFDEF SPECTRANET
    include "spectranet.asm"
    ENDIF

    
open_lbl db 'Opening connection to ', 0

path    db '/uhello'
        defs 248              
server  db 'nihirash.net'
        defs 58    
port    db '70'
        defs 5
        db 0
page_buffer equ $
    display "PAGE buffer:", $
    IFNDEF ZX48
no128k  db 13, "You're in 48k mode!", 13, 13
        db     "Current version require full", 13 
        db     "128K memory access", 13, 13
        db     "System halted!", 0
    ENDIF
    IFNDEF ZX48
player 
    DISPLAY "Player starts:" , $       
    include "vtpl.asm"
    DISPLAY "Player ends: ", $
    ENT
    ENDIF
eop equ $
    SAVEBIN "ugoph.bin", Start, $ - Start
    
    SAVETAP "ugoph.tap", Start
    