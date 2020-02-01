all: setspeed

setspeed: main.asm data.asm
	sjasmplus main.asm

data.asm: makedata.c
	gcc makedata.c -o makedata
	./makedata >data.asm

clean: 
	rm setspeed
