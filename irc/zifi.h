#ifndef ZIFI_H
#define ZIFI_H 1

// ESX API
#define ESX_GETSETDRV 0x89
#define ESX_FOPEN 0x9A
#define ESX_FCLOSE 0x9B
#define ESX_FSYNC 0x9C
#define ESX_FREAD 0x9D
#define ESX_FWRITE 0x9E

// File Modes
#define FMODE_READ 0x01
#define FMODE_WRITE 0x06
#define FMODE_CREATE 0x0E

extern char* ssid;
extern char* wpass;
extern char is_connected;

void initWifi();
char openTcp(char *host, char *port);
char isAvail();
char sendByte(char c);
char getByte();

#endif