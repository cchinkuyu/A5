/*--------------------------------------------------------------------*/
/* stressed.c                                                         */
/* Author: Chimwemwe Chinkuyu                                         */
/*--------------------------------------------------------------------*/

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>


/* The program creates a file with 50,000 random characters. Between
  consisting of 0x09, 0x0A, and 0x20 through 0x7E.*/
int main(void) {
    int iCounter = 0;
    int iChar;

    for (; iCounter < 50000; iCounter++) {
        iChar = rand();

        iChar %= 0x7F;

        if(((iChar < 0x7F) && (iChar >= 0x20)) || (iChar == 0x09) ||
         (iChar == 0x0A)) {
            putchar(iChar);
        }
        else {
            iCounter--;
        }
    }
}