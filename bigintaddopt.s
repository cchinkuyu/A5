/*--------------------------------------------------------------------*/
/* bigintaddopt.s                                                     */
/* Author: Chimwemwe Chinkuyu                                         */
/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */
// enum {FALSE, TRUE};
        .equ FALSE, 0
        .equ TRUE, 1
        .equ MAX_DIGITS, 32768
/*--------------------------------------------------------------------*/

        .section .text

/* Return the larger of lLength1 and lLength2. */
// static long BigInt_larger(long lLength1, long lLength2)

        .equ BI_LARGER_STACK_BYTECOUNT, 32

        // Local variable registers
        LLARGER .req x21
        
        // Function parameter registers
        LLENGTH1 .req x20
        LLENGTH2 .req x19

BigInt_larger:

    // Prolog
    sub     sp, sp, BI_LARGER_STACK_BYTECOUNT
    str     x30, [sp]
    str     LLENGTH2, [sp, 8]
    str     LLENGTH1, [sp, 16]
    str     LLARGER, [sp, 24]

    // Store parameters in registers
    mov     LLENGTH2, x0
    mov     LLENGTH1, x1

    // long lLarger;

    // if (lLength1 <= lLength2) goto else1;
    cmp     LLENGTH1, LLENGTH2
    ble     else1

    // lLarger = lLength1;
    mov     LLARGER, LLENGTH1

    // goto endif;
    b       endif

    else1:
    // lLarger = lLength2;
    mov     LLARGER, LLENGTH2

    endif:

    // return lLarger;
    mov     x0, LLARGER    
    ldr     x30, [sp]
    ldr     LLENGTH2, [sp, 8]
    ldr     LLENGTH1, [sp, 16]
    ldr     LLARGER, [sp, 24]
    add     sp, sp, BI_LARGER_STACK_BYTECOUNT
    ret

    .size BigInt_larger, (.-BigInt_larger)

/*--------------------------------------------------------------------*/

/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
overflow occurred, and 1 (TRUE) otherwise. */

        .global BigInt_add
        
// int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
BigInt_add:

        .equ BI_ADD_STACK_BYTECOUNT, 64

        // Local variable registers
        ULCARRY .req x25
        ULSUM .req x24
        LINDEX .req x23
        LSUMLENGTH .req x22

        // Parameter registers
        OADDEND1 .req x21
        OADDEND2 .req x20
        OSUM .req x19

        // Struct offset
        .equ ARRAY_OFFSET, 8


    // unsigned long ulCarry;
    // unsigned long ulSum;
    // long lIndex;
    // long lSumLength;

    // assert(oAddend1 != NULL);
    // assert(oAddend2 != NULL);
    // assert(oSum != NULL);
    // assert(oSum != oAddend1);
    // assert(oSum != oAddend2);

        // Prolog
        sub     sp, sp, BI_ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     OSUM, [sp, 8]
        str     OADDEND2, [sp, 16]
        str     OADDEND1, [sp, 24]
        str     LSUMLENGTH, [sp, 32]
        str     LINDEX, [sp, 40]
        str     ULSUM, [sp, 48]
        str     ULCARRY, [sp, 56]

        // Store parameters in registers
        mov     OSUM, x0
        mov     OADDEND2, x1
        mov     OADDEND1, x2

    /* Determine the larger length. */

    /* NEED TO DO TWO LDRs one for pointer and another to get its value*/
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        mov     x0, OADDEND1
        mov     x1, OADDEND2
        bl      BigInt_larger
        mov     LSUMLENGTH, x0

    /* Clear oSum's array if necessary. */
    // if (oSum->lLength <= lSumLength) goto endif2;
        mov     x0, OSUM
        cmp     x0, LSUMLENGTH
        ble     endif2

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        mov     x0, OSUM
        add     x0, x0, ARRAY_OFFSET
        mov     w1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, 3
        bl      memset

    endif2:

    /* Perform the addition. */
        // ulCarry = 0;
        mov     w0, 0
        mov     ULCARRY, x0

        // lIndex = 0;
        // NOTE: w0 still contains 0
        mov     LINDEX, x0

    addLoop:
        // if (lIndex >= lSumLength) goto endaddLoop;
        cmp     LINDEX, LSUMLENGTH
        bge     endaddLoop

        // ulSum = ulCarry;
        mov     ULSUM, ULCARRY

        // ulCarry = 0;
        // NOTE: w0 still contains 0
        mov     ULCARRY, x0


        // ulSum += oAddend1->aulDigits[lIndex];
        mov     x0, OADDEND1
        add     x0, x0, ARRAY_OFFSET
        ldr     x1, [x0, LINDEX, lsl 3]
        add     ULSUM, ULSUM, x1

        /* Check for overflow. */
        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endif3;
        // NOTE: x1 still holds the cell value
        cmp     ULSUM, x1
        bhs     endif3

        // ulCarry = 1;
        mov     w0, 1
        mov     ULCARRY, x0

    endif3:

        // ulSum += oAddend2->aulDigits[lIndex];
        mov     x0, OADDEND2
        add     x0, x0, ARRAY_OFFSET
        ldr     x1, [x0, LINDEX, lsl 3]
        add     ULSUM, ULSUM, x1

        /* Check for overflow. */
        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4;
        // NOTE: x1 still holds the cell value
        cmp     ULSUM, x1
        bhs     endif4

        // ulCarry = 1;
        mov     w0, 1
        mov     ULCARRY, x0

    endif4:

        // oSum->aulDigits[lIndex] = ulSum;
        mov     x0, OSUM
        add     x0, OSUM, ARRAY_OFFSET
        str     ULSUM, [x0, LINDEX, lsl 3]

        // lIndex++;
        add     LINDEX, LINDEX, 1

        // goto addLoop;
        b       addLoop

    endaddLoop:

    /* Check for a carry out of the last "column" of the addition. */
        // if (ulCarry != 1) goto endif5;
        cmp     ULCARRY, 1
        bne     endif5

        // if (lSumLength != MAX_DIGITS) goto endif6;
        cmp     LSUMLENGTH, MAX_DIGITS
        bne     endif6

        // return FALSE;
        ldr     x30, [sp]
        ldr     OSUM, [sp, 8]
        ldr     OADDEND2, [sp, 16]
        ldr     OADDEND1, [sp, 24]
        ldr     LSUMLENGTH, [sp, 32]
        ldr     LINDEX, [sp, 40]
        ldr     ULSUM, [sp, 48]
        ldr     ULCARRY, [sp, 56]
        mov     w0, FALSE
        add     sp, sp, BI_ADD_STACK_BYTECOUNT
        ret     

    endif6:

        // oSum->aulDigits[lSumLength] = 1;
        mov     x0, OSUM
        add     x0, x0, ARRAY_OFFSET
        mov     w1, 1        
        str     x1, [x0 , LSUMLENGTH, lsl 3]

        // lSumLength++;
        add     LSUMLENGTH, LSUMLENGTH, 1

    endif5:

    /* Set the length of the sum. */
        // oSum->lLength = lSumLength;
        mov     OSUM, LSUMLENGTH
        
        // return TRUE;
        ldr     x30, [sp]
        ldr     OSUM, [sp, 8]
        ldr     OADDEND2, [sp, 16]
        ldr     OADDEND1, [sp, 24]
        ldr     LSUMLENGTH, [sp, 32]
        ldr     LINDEX, [sp, 40]
        ldr     ULSUM, [sp, 48]
        ldr     ULCARRY, [sp, 56]
        mov     w0, TRUE
        add     sp, sp, BI_ADD_STACK_BYTECOUNT
        ret

        .size BigInt_add, (. - BigInt_add)

