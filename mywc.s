//----------------------------------------------------------------------
// mywc.s
// Author: Chimwemwe Chinkuyu
//----------------------------------------------------------------------

        .equ FALSE, 0
        .equ TRUE, 1
        .equ EOF, -1

        .section .rodata

printfFormatStr:
        .string "%7ld %7ld %7ld\n"

//----------------------------------------------------------------------

        .section .data

lLineCount:
        .quad   0
lWordCount:
        .quad   0
lCharCount:
        .quad   0
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
        // if ((iChar = getchar()) == EOF) goto endcharLoop;
        bl      getchar
        adr     x1, iChar
        str     w0, [x1]
        cmp     w0, EOF
        beq     endcharLoop

        // lCharCount++
        adr     x0, lCharCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // if (!isspace(iChar)) goto else1
        adr     x0, iChar
        ldr     w0, [x0]
        bl      isspace
        cmp     w0, FALSE
        beq     else1

        // if (!iInWord) goto if4
        adr     x0, iInWord
        ldr     w0, [x0]
        cmp     x0, FALSE
        beq     if4

        // lWordCount++
        adr     x0, lWordCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // iInWord = FALSE
        adr     x0, iInWord
        mov     w1, FALSE
        str     w1, [x0]

        // goto if4
        b       if4

   else1:
        // if (iInWord) goto if4
        adr     x0, iInWord
        ldr     w0, [x0]
        cmp     x0, TRUE
        beq     if4

        // iInWord = TRUE
        adr     x0, iInWord
        mov     w1, TRUE
        str     w1, [x0]

      if4:
        // if (iChar != '\n') goto charLoop
        adr     x0, iChar
        ldr     w0, [x0]
        cmp     w0, '\n'
        bne     charLoop

        // lLineCount++
        adr     x0, lLineCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

	    // goto charLoop
        b       charLoop

   endcharLoop:

        // if (!iInWord) goto endif5
        adr     x0, iInWord
        ldr     w0, [x0]
        cmp     w0, FALSE
        beq     endif5

        // lWordCount++
        adr     x0, lWordCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

endif5:

        // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        adr     x0, printfFormatStr
        adr     x1, lLineCount
        ldr     x1, [x1]
        adr     x2, lWordCount
        ldr     x2, [x2]
        adr     x3, lCharCount
        ldr     x3, [x3]
        bl      printf

        // Epilog
        mov     w0, 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT

        // return 0
        ret

        .size main, (. - main)

