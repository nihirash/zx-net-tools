# WGet for ZX-Spectrum 128K with esxDOS and ESP-12 on AY chip

This tool made for downloading something from HTTP(https doesn't supported) and storing to SD card via esxDOS.

## Usage

Download from releases WGET and put it to `/BIN` directory of speccy's SD Card(or divIDE's drive). 

By restriction Sinclair Basic you can't use `:` symbol in url(you may skip it in protocol part), but you must keep double slashes at url start.

To download `http://artisia.net/out.scr` to `test.scr` you must enter this thing: 

```
.wget //artisia.net/out.scr test.scr
```

or 

```
.wget http//artisia.net/out.scr test.scr
```

## Legals

Made by Alexander Sharikhin

Originally made for ZX-Uno. 

Some part of code(preparing HTTP-request) based on [ZiFi project](https://github.com/HackerVBI/ZiFi/).

This code is public domain.