/*--------------------------------------------------------------------*/
/* bigintadd.s                                                        */
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
        // Stack offset for local variable
        .equ LLARGER, 8
        // Stack offset for function parameters
        .equ LLENGTH1, 16
        .equ LLENGTH2, 24

BigInt_larger:

    // Prolog
    sub     sp, sp, BI_LARGER_STACK_BYTECOUNT
    str     x30, [sp]
    str     x0, [sp, LLENGTH1]
    str     x1, [sp, LLENGTH2]

    // long lLarger;

    // if (lLength1 <= lLength2) goto else1;
    ldr     x0, [sp, LLENGTH1]
    ldr     x1, [sp, LLENGTH2]
    cmp     x0, x1
    ble     else1

    // lLarger = lLength1;
    ldr     x0, [sp, LLENGTH1]
    str     x0, [sp, LLARGER]

    // goto endif;
    b       endif

    else1:
    // lLarger = lLength2;
    ldr     x0, [sp, LLENGTH2]
    str     x0, [sp, LLARGER]

    endif:
    // return lLarger;
    ldr     x0, [sp, LLARGER]
    ldr     x30, [sp]
    add     sp, sp, BI_LARGER_STACK_BYTECOUNT
    ret

    .size BigInt_larger, (.-BigInt_larger)

/*--------------------------------------------------------------------*/

/* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
overflow occurred, and 1 (TRUE) otherwise. */

// int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
BigInt_add:

        .equ BI_ADD_STACK_BYTECOUNT, 64
        // Stack offset for local variables
        .equ ULCARRY, 8
        .equ ULSUM, 16
        .equ LINDEX, 24
        .equ LSUMLENGTH, 32
        // Stack offset for parameters
        .equ OADDEND1, 40
        .equ OADDEND2, 48
        .equ OSUM, 56
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
        str     x0, [sp, OADDEND1]
        str     x1, [sp, OADDEND2]
        str     x2, [sp, OSUM]

    /* Determine the larger length. */

    /* NEED TO DO TWO LDRs one for pointer and another to get its value*/
    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        ldr     x0, [sp, OADDEND1]
        ldr     x0, [x0]
        ldr     x1, [sp, OADDEND2]
        ldr     x1, [x1]
        bl      BigInt_larger
        str     x0, [sp, LSUMLENGTH]

    /* Clear oSum's array if necessary. */
    // if (oSum->lLength <= lSumLength) goto endif2;
        ldr     x0, [sp, OSUM]
        ldr     x0, [x0]
        ldr     x1, [sp, LSUMLENGTH]
        cmp     x0, x1
        ble     endif2

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        ldr     x0, [sp, OSUM]
        add     x0, x0, ARRAY_OFFSET
        mov     w1, 0
        mov     x2, MAX_DIGITS
        lsl     x2, x2, 3
        bl      memset

    endif2:

    /* Perform the addition. */
        // ulCarry = 0;
        mov     x0, 0
        str     x0, [sp, ULCARRY]

        // lIndex = 0;
        mov     x0, 0
        str     x0, [sp, LINDEX]

    addLoop:
        // if (lIndex >= lSumLength) goto endaddLoop;
        ldr     x0, [sp, LINDEX]
        ldr     x1, [sp, LSUMLENGTH]
        cmp     x0, x1
        bge     endaddLoop

        // ulSum = ulCarry;
        ldr     x0, [sp, ULCARRY]
        str     x0, [sp, ULSUM]

        // ulCarry = 0;
        mov     x0, 0
        str     x0, [sp, ULCARRY]


        // ulSum += oAddend1->aulDigits[lIndex];
        ldr     x0, [sp, ULSUM]
        ldr     x1, [sp, OADDEND1]
        add     x1, x1, ARRAY_OFFSET
        ldr     x2, [sp, LINDEX]
        ldr     x3, [x1, x2, lsl 3]
        add     x0, x0, x3
        str     x0, [sp, ULSUM]

        /* Check for overflow. */
        // if (ulSum >= oAddend1->aulDigits[lIndex]) goto endif3;
        // NOTE: x0 still holds ulSum and x3 holds the cell value
        cmp     x0, x3
        bhs     endif3

        // ulCarry = 1;
        mov     x0, 1
        str     x0, [sp, ULCARRY]

    endif3:

        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x0, [sp, ULSUM]
        ldr     x1, [sp, OADDEND2]
        add     x1, x1, ARRAY_OFFSET
        ldr     x2, [sp, LINDEX]
        ldr     x3, [x1, x2, lsl 3]
        add     x0, x0, x3
        str     x0, [sp, ULSUM]

        /* Check for overflow. */
        // if (ulSum >= oAddend2->aulDigits[lIndex]) goto endif4;
        // NOTE: x0 still holds ulSum and x3 holds the cell value
        cmp     x0, x3
        bhs     endif4

        // ulCarry = 1;
        mov     x0, 1
        str     x0, [sp, ULCARRY]

    endif4:

        // oSum->aulDigits[lIndex] = ulSum;
        ldr     x0, [sp, ULSUM]
        ldr     x1, [sp, OSUM]
        add     x1, x1, ARRAY_OFFSET
        ldr     x2, [sp, LINDEX]
        str     x0, [x1, x2, lsl 3]

        // lIndex++;
        ldr     x0, [sp, LINDEX]
        add     x0, x0, 1
        str     x0, [sp, LINDEX]

        // goto addLoop;
        b       addLoop

    endaddLoop:

    /* Check for a carry out of the last "column" of the addition. */
        // if (ulCarry != 1) goto endif5;
        ldr     x0, [sp, ULCARRY]
        cmp     x0, 1
        bne     endif5

        // if (lSumLength != MAX_DIGITS) goto endif6;
        ldr     x0, [sp, LSUMLENGTH]
        cmp     x0, MAX_DIGITS
        bne     endif6

        // return FALSE;
        mov     w0, FALSE
        ldr     x30, [sp]
        add     sp, sp, BI_ADD_STACK_BYTECOUNT
        ret     

    endif6:

        // oSum->aulDigits[lSumLength] = 1;
        ldr     x0, [sp, OSUM]
        add     x0, x0, ARRAY_OFFSET
        ldr     x1, [sp, LSUMLENGTH]
        mov     x2, 1        
        str     x2, [x0 , x1, lsl 3]

        // lSumLength++;
        ldr     x0, [sp, LSUMLENGTH]
        add     x0, x0, 1
        str     x0, [sp, LSUMLENGTH]

    endif5:

    /* Set the length of the sum. */
        // oSum->lLength = lSumLength;
        ldr     x0, [sp, LSUMLENGTH]
        ldr     x1, [sp, OSUM]
        str     x0, [x1]
        
        // return TRUE;
        mov     w0, TRUE
        ldr     x30, [sp]
        add     sp, sp, BI_ADD_STACK_BYTECOUNT
        ret

