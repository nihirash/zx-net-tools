#include <stdio.h>

char *string = "\r\nAT+UART_DEF=9600,8,1,0,2\r\n";
char counter = 0; 

void transmitZero()
{
    printf(" #f6, ");
}

void transmitOne()
{
    printf(" #fe, ");
}

void byteToSequence(char c)
{
    counter++;
    printf("\n    db ");
    transmitZero();
    for (int i=0;i<8;i++) {
        if ((c & 1<< i) != 0)
            transmitOne();
        else
            transmitZero();
    }
    printf(" #fe");
}

int main(int argc, char **args)
{
    printf("dataSequence:\n");
    for (int i=0;string[i];i++)
        byteToSequence(string[i]);

    printf("\ndataSize = $ - dataSequence");
    printf("\n; Total bytes %u ", counter);
    printf("\n");
    return 0;
}
