all:
	@echo "This application works only with esxDOS"
	@echo ""
	@echo "make zxuno - for build it for zxuno"
	@echo "make esxdos - for build it for any zxspectrum with esxDos and ESP on AY-chip"

zxuno: *.asm
	sjasmplus -DUNO main.asm

esxdos: *.asm
	sjasmplus -DAY main.asm

clean: 
	rm WGET
