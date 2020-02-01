#include <stdio.h>
#include <conio.h>
#include <spectrum.h>
#include "zifi.h"

char host[80];
char port[6];

char nick[40];
char pass[40];
char channel[256];

char recvBuff[4096];
char sendBuff[1024];
char iBuff[255];
unsigned char iPos = 0;

char intBuff[80];
char msgOutBuff[1024];

static void myPutS(char *c);
static void iRoutine();

static void setColour(char c) 
{
    printf("%c%c", 16, c);
}


static void cleanStatus() 
{

    gotoxy(0, 22);
    printf("                                                                ");
}

static void cleanIRow()
{
    gotoxy(0, 23);
    printf("                                                                "); 
}

static char* skip(char *s, char c) 
{
	while(*s != c && *s != '\0')
		s++;
	if(*s != '\0')
		*s++ = '\0';
	return s;
}

static void trim(char *s) 
{
	char *e;

	e = s + strlen(s) - 1;
	while(isspace(*e) && e > s)
		e--;
	*(e + 1) = '\0';
}


void readHostData()
{
    printf("Enter host: ");
    cgets(host);
 
    printf("Enter port(or keep empty for 6667):");
    cgets(port);
    if (!strcmp(port,"")) {
        strcpy(port, "6667");
    }
}

void readUserData()
{
    printf("Your nick:");
    cgets(nick);
    if (!strcmp(nick, "")) {
        strcpy(nick, "anon-spectrum");
    }

    printf("Your password(may keep empty): ");
    cgets(pass);
}

static void send()
{
    int i;
    for (i=0; sendBuff[i] != 0; i++)
        sendByte(sendBuff[i]);
    
    sendByte('\r');
    sendByte('\n');
}

static void recv()
{
    int i = 0; char j;
    while (i < 4095) {
            recvBuff[i] = getByte();
            if (recvBuff[i] == 10 || recvBuff[i] == 13) break;
            if (recvBuff[i]>31) i++; else {
                __asm
                    ei
                    halt
                __endasm;
                
                iRoutine();
            
            }
    }

    recvBuff[i] = 0;
} 

void connect()
{
    if (strlen(pass) > 0) {
        sprintf(&sendBuff, "PASS %s", pass);
        send();
    }

    sprintf(&sendBuff, "NICK %s", nick);
    send();

    sprintf(&sendBuff, "USER %s localhost %s :%s", nick, host, nick);
    send();
}

static void privmsg(char *to, char *what) 
{
    if (to[0] == 0) {
        setColour( '5' );
        myPutS("No target to send message!");
        return;
    }

    if (what[0] == 0) return;

    sprintf(sendBuff, "PRIVMSG %s : %s", to, what);
    send();

    sprintf(intBuff, "<%s> %s", nick, what);    
    setColour( '3' );
    myPutS(intBuff);
} 

static void myPutS(char *c)
{
    cleanStatus();
    cleanIRow();

    gotoxy(0, 20);
    printf("%s\n\n\n\n", c);

}

static void parseIn()
{
    char *subStr, cnt;
    char argBuff[40];
    if (iBuff[0] == 0) return;
    if (iBuff[0] != '!') {
        privmsg(channel, iBuff);
        return;
    }

    if (iBuff[1] != 0 && iBuff[2] == ' ') {
        subStr = &iBuff + 3;
        switch (iBuff[1])
        {
        case 'j':
            sprintf(sendBuff, "JOIN %s", subStr);
            send();
            strcpy(channel, subStr);
            sprintf(intBuff, "Current stream: %s", subStr);
            setColour( '7' );
            myPutS(intBuff);
            break;
        case 's':
            strcpy(channel, subStr);
            sprintf(intBuff, "Current stream: %s", subStr);
            setColour( '7' );
            myPutS(intBuff);
            break;
        case 'l':
            if (channel[0]) {
                sprintf(sendBuff, "PART %s :%s", channel, subStr);
                send();
                channel[0] = 0;

                setColour( '7' );
                myPutS("Select stream or join group to talk");
                return;
            }
        case 'm':
            for (cnt=0;(subStr[cnt] != ' ') && (subStr[cnt] != 0) ; argBuff[cnt] = subStr[cnt ++]);
            
            argBuff[cnt] = 0;

            if (subStr[cnt] == ' ') { 
                privmsg(argBuff, &subStr[++ cnt]);
            }
            else {
                setColour( '5' );
                myPutS("No message specified!");
            }
        default:
            break;
        }
    } else {
        if (iBuff[1] == 'l' && iBuff[2] == 0) {
            if (channel[0]) {
                sprintf(sendBuff, "PART %s", channel);
                send();
                channel[0] = 0;

                return;
            }
        } else {
            strcpy(sendBuff, &iBuff[1]);
            send();
        }
    }
}

static void parseSrv(char *cmd)
{
    char *usr, *par, *txt;

	usr = host;
	if(!cmd || !*cmd)
		return;

	if(cmd[0] == ':') {
		usr = cmd + 1;
		cmd = skip(usr, ' ');
		if(cmd[0] == '\0')
			return;
		skip(usr, '!');
	}
	skip(cmd, '\r');
	par = skip(cmd, ' ');
	txt = skip(par, ':');
	trim(par);
    if (!strcmp("PONG", cmd)) return;
    if(!strcmp("PRIVMSG", cmd)) {
        sprintf(msgOutBuff, "%s <%s> %s", par, usr, txt);
        setColour ( '2' );
        myPutS(msgOutBuff);
        return;
    }

    if (!strcmp("PING", cmd)) {
        sprintf(sendBuff, "PONG %s", txt);
        send();
        return;
    }

    if (!strcmp("NICK", cmd)) {
        strcpy(nick, txt);
    }
    sprintf(msgOutBuff, "%s!%s(%s): %s", usr, cmd, par, txt);
    
    setColour( '5' );
    myPutS(msgOutBuff);
}    


static void bar()
{
    gotoxy(0, 22);
    setColour( '7' );
    printf("Current stream: %s", channel);
    __asm
        ld hl, #0x5AC0
        ld a, #0x0F
        ld (hl), a
        ld de, #0x5AC1
        ld bc, #31
        ldir
    __endasm;
}

static void iRoutine()
{
    char c;
    unsigned char i = 0;
    setColour( '7' );

    gotoxy(0, 23);
    iBuff[iPos] = 0;
    
    if (iPos > 62) i = iPos - 62;

    c = getk();
    printf(">%s_", &iBuff[i], c);
    
    if (c >= 32) iBuff[iPos ++] = c;
    if (c == 12) {
        if (i < 2)
            cleanIRow();

        iPos --;
    }
    if (c == 13) { 
        cleanIRow();
        iPos = 0;
        parseIn();
        bar();

    }
    if (iPos < 0) iPos = 0;
    if (iPos > 254) iPos = 254;
}


void main() 
{
    char i;
    zx_border(INK_BLACK);
    zx_colour(PAPER_BLACK | INK_WHITE);
    clg();
    __asm
        ld a, 7
        ld (23695), a
        ld (23693), a
    __endasm;

    setColour( '5' );
    
    myPutS("Simple IRC Client for ZX-128 v. 0.3");
    setColour( '3' );
    
    myPutS("(c) 2020 Nihirash");
    myPutS("Some parts based on Simple Irc Client(suckless software)");
    myPutS("This software is Public Domain.");
    myPutS("Use it for the good of all beings");
    myPutS("");
    setColour ( '7' );
    readHostData();
    readUserData();
    initWifi();
    openTcp(host, port);
    myPutS("Connected!");
    recv();
    parseSrv(recvBuff);
    connect();
    bar();
    for(;;) {
        for (i = 0; i < 10; i++) {
            __asm
                ei
                halt
            __endasm;
            iRoutine();
        }

        if (isAvail()) {
            recv();
            parseSrv(recvBuff);
            bar();
        }
    }
}