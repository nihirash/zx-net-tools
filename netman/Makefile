all: 
	@echo "To make Network Manager please select target"
	@echo ""
	@echo "make zxuno - to make esxDOS ZX-Uno version"
	@echo "make zxuno3e - to make +3e ZX-Uno version"
	@echo "make plus3dos - to make +3/+3e version Spectrum 128 with ESP-12 on AY"
	@echo "make esxdos - to make esxDOS version Spectrum 128 with ESP-12 on AY"

zxuno: *.asm font.bin
	sjasmplus -DESXDOS -DUNO main.asm

zxuno3e: *.asm font.bin
	sjasmplus -DPLUS3DOS -DUNO main.asm
	specform -a 32768 netman.bin
	rm netman.bin
	mv netman.bin.zxb netman.bin

esxdos: *.asm font.bin
	sjasmplus -DESXDOS -DAY main.asm
	
plus3dos:	
	sjasmplus -DPLUS3DOS -DAY main.asm
	specform -a 32768 netman.bin
	rm netman.bin
	mv netman.bin.zxb netman.bin
	
clean:
	rm netman.bin netman.tap