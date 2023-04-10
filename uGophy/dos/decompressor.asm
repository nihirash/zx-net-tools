;f0o6g0
sauk:   ld      bc, 32768
        ld      a, b
copyby: inc     c
        ldi
mainlo: call    getbit
        jr      nc, copyby
        push    de
        ld      d, c
lenval: call    nc, getbit
        rl      c
        rl      b
        call    getbit
        jr      nc, lenval
        inc     c
        jr      z, exitdz
        ld      e, (hl)
        inc     hl
        defb    203, 51
        jr      nc, offend
        ld      d, 4
nexbit: call    getbit
        rl      d
        jr      nc, nexbit
        inc     d
        srl     d
offend: rr      e
        ex      (sp), hl
        push    hl
        sbc     hl, de
        pop     de
        ldir
exitdz: pop     hl
        jr      nc, mainlo
getbit: add     a, a
        ret     nz
        ld      a, (hl)
        inc     hl
        adc     a, a
        ret
