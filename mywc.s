//----------------------------------------------------------------------
// mywc.s
// Author: Chimwemwe Chinkuyu
//----------------------------------------------------------------------

        .section .rodata

printfFormatStr:
        .string "%7ld %7ld %7ld\n"

//----------------------------------------------------------------------

        .section .data

lLineCount:
        .quad   1
lWordCount:
        .quad   1
lCharCount:
        .quad   1
iInWord:
        .word   FALSE

//----------------------------------------------------------------------

        .section .bss

iChar:
        .skip   4

//----------------------------------------------------------------------

        .section .text

        //--------------------------------------------------------------
        // Write to stdout counts of how many lines, words, and
        // characters are in stdin. A word is a sequence of
        // non-whitespace characters. Whitespace is defined by the
        // isspace() function. Return 0.
        //--------------------------------------------------------------

        // Must be a multiple of 16
        .equ    MAIN_STACK_BYTECOUNT, 16

        .global main

main:
        // Prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

charLoop:
        // if (!(iChar = getchar()) != EOF) goto endcharLoop;
        adr     x0, iChar
        ldr     x0, [x0]
        bl      getchar
        adr     x1, EOF
        cmp     x0, x1
        blo     endcharLoop

        // lCharCount++
        adr     x0, lCharCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // if1 (!isspace(iChar)) goto else1
        adr     x0, iChar
        ldr     x0, [x0]
        bl      isspace
        adr     x1, FALSE
        cmp     x0, x1
        beq     else1

        // if2 (!iInWord) goto if4
        adr     x0, iInWord
        adr     x1, FALSE
        cmp     x0, x1
        beq     if4

        // lWordCount++
        adr     x0, lWordCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // iInWord = FALSE
        adr     x0, iInWord
        ldr     x0, [x0]
        ldr     x1, FALSE
        str     x0, x1







