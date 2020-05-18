showText:
    DISPLAY "show text: ", $
    xor a : ld (show_offset), a, (s_half), a 
reRenderText:
    call renderTextScreen
showTxLp:
    call txControls
    IFNDEF ZX48
    xor a : call changeBank
    ENDIF
    dup 5
    halt
    edup
    jp showTxLp

txControls:
    call inkey
    
    and a : ret z

    cp 'q' : jp z, txUp
    cp 'o' : jp z, txUp
    cp 'a' : jp z, txDn
    cp 'p' : jp z, txDn
    cp 'b' : jp z, .justBack
    cp 'n' : jp z, openURI
    cp 32  : jp z, .toggleHalf
    ret
.justBack
    pop af 
    jp historyBack
.toggleHalf
    pop af
    ld a, (s_half) : xor #ff : ld (s_half), a
    jp reRenderText

txUp:
    ld a, (show_offset)
    and a : ret z

    sub 20 : ld (show_offset), a
    call renderTextScreen
    ret

txDn:
    ld a, (show_offset) 
    add 20 : ld (show_offset), a

    call renderTextScreen
    ret

renderTextScreen:
    DISPLAY "renderTextScreen: ", $
    call renderHeader
    ld b, 20
.loop
    push bc
    
    ld a, 20 : sub b : ld b, a : ld a, (show_offset) : add b : ld b, a 
    call renderTextLine
    
    pop bc
    djnz .loop
    DISPLAY "CRASH HERE?", $
    ret


renderTextLine:
    call findLine
    
    ld a, h : or l : ret z
    
    ld a, (hl) : and a : ret z
    ld a, (s_half) : and a : call nz, skipHalf64T
    call printL64
    call mvCR
    ret
