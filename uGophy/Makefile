all:
	@echo "To make ugophy please select target"
	@echo ""
	@echo "make zxuno - to make esxDOS ZX-Uno version"
	@echo "make zxuno3e - to make +3e ZX-Uno version"
	@echo "make plus3dos - to make +3/+3e version Spectrum 128 with ESP-12 on AY"
	@echo "make esxdos - to make esxDOS version Spectrum 128 with ESP-12 on AY"
	@echo "make spectranet - to make Spectranet version"
	@echo "make karabaspro - to make TR-DOS version for karabas-pro with UNO UART"
	@echo "make karabaspro-zifi - to make TR-DOS version for karabas-pro with ZIFI UART"

player.bin:
	sjasmplus -DTRDOS vtpl.asm

spectranet: *.asm font.bin
	sjasmplus -DSPECTRANET main.asm
	scp ugoph.bin root@nihirash.net:/var/tnfs/ugoph.bin

spectranet48: *.asm font.bin
	sjasmplus -DSPECTRANET -DZX48 main.asm
	scp ugoph.bin root@nihirash.net:/var/tnfs/ugoph48.bin

karabaspro: *.asm font.bin player.bin
	sjasmplus -DTRDOS -DUNO -DPROFISCR main.asm

karabaspro-zifi: *.asm font.bin player.bin
	sjasmplus -DTRDOS -DZIFI -DPROFISCR main.asm

karabaspro-debug: *.asm font.bin player.bin
	sjasmplus -DDEBUG -DTRDOS -DZIFI -DPROFISCR main.asm
	wine /home/andy/Downloads/unreal/unreal.exe ugoph.sna

zxuno: *.asm font.bin
	sjasmplus -DESXDOS -DUNO -DTIMEXSCR main.asm

zxuno3e: *.asm font.bin
	sjasmplus -DPLUS3DOS -DUNO main.asm
	specform -a 24100 ugoph.bin
	rm ugoph.bin
	mv ugoph.bin.zxb ugoph.bin

plus3dos: *.asm font.bin
	sjasmplus -DPLUS3DOS -DAY main.asm
	specform -a 24100 ugoph.bin
	rm ugoph.bin
	mv ugoph.bin.zxb ugoph.bin

esxdos: *.asm font.bin
	sjasmplus -DESXDOS -DAY main.asm

tape: *.asm font.bin
	sjasmplus -DTAPE -DAY main.asm

clean:
	rm ugoph.bin *.tap ugoph.?c player.bin ugoph.sna

