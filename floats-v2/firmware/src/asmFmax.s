/*** asmFmax.s   ***/

.syntax unified

/* Declare the following to be in data memory */
.data  
.align

/* Define the globals so that the C code can access them */

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Jesus Hernandez"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
/* use these locations to store f0 values */
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
/* use these locations to store f1 values */
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
/* use these locations to store fMax values */
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

/* Tell the assembler that what follows is in instruction memory     */
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    
    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* The 15 result words (5 for f0, 5 for f1, 5 for fMax) sit back to
     * back in data memory starting at f0. Walk through them with a
     * pointer so every field starts from a clean 0 on each call */
    LDR r4, =f0         /* pointer to the first result word */
    MOV r5, 0           /* the value every field is reset to */
    MOV r6, 15          /* number of words still left to clear */

init_loop:
    /* Clear the current word, then post-index the pointer by 4 bytes
     * so it moves to the next word for the next pass */
    STR r5, [r4], 4
    SUBS r6, r6, 1      /* one fewer word left; sets Z when all are done */
    BNE init_loop

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    
/* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Fetch the raw 32-bit pattern of the float the caller pointed to */
    LDR r4, [r0]

    /* The sign is bit 31. A logical shift right by 31 moves it down to
     * bit 0 and fills the rest with 0s, leaving 1 for negative and 0
     * for positive, which is the format the caller's variable expects */
    LSR r4, r4, 31
    STR r4, [r1]        /* save the sign bit where the caller asked */

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function does NOT
                check for +/-Inf or +/-0, so r1 ALWAYS contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    
    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Fetch the raw 32-bit pattern of the float the caller pointed to */
    LDR r4, [r0]

    /* The stored exponent is bits 23-30. Shifting left by 1 throws away
     * the sign bit, then shifting right by 24 drops the mantissa and
     * leaves just the 8 exponent bits in the low byte (range 0-255) */
    LSL r4, r4, 1
    LSR r4, r4, 24

    /* Return the stored exponent in r0, and the unbiased (real)
     * exponent in r1 by removing the IEEE-754 bias of 127. Special
     * cases like a stored exponent of 0 are handled by the caller */
    MOV r0, r4
    SUB r1, r4, 127

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    
    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Fetch the raw 32-bit pattern of the float the caller pointed to */
    LDR r4, [r0]

    /* The mantissa is bits 0-22. Shifting left by 9 pushes the sign and
     * exponent bits out the top, and shifting back right by 9 refills
     * those 9 bits with 0s, leaving only the raw 23-bit mantissa */
    LSL r4, r4, 9
    LSR r4, r4, 9

    /* r0 returns the mantissa exactly as stored. r1 returns the same
     * mantissa with the hidden leading 1 restored in bit 23, which is
     * what a normalized float's true significand looks like */
    MOV r0, r4
    ORR r1, r4, 0x00800000

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    
    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Fetch the raw 32-bit pattern of the float the caller pointed to */
    LDR r4, [r0]

    /* +0 is the only float whose bits are all 0 */
    CMP r4, 0
    BEQ zero_pos

    /* -0 is the only float with just the sign bit set */
    CMP r4, 0x80000000
    BEQ zero_neg

    /* Any other bit pattern is a nonzero value, so report "not zero" */
    MOV r0, 0
    B zero_done

zero_pos:
    MOV r0, 1           /* report +0 to the caller */
    B zero_done

zero_neg:
    MOV r0, -1          /* report -0 to the caller */

zero_done:
    /* The result code is already in r0 as the return value.
     * Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to follow the calling convention! */

    /* Save the callee-saved registers and the return address so this
     * function follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Fetch the raw 32-bit pattern of the float the caller pointed to */
    LDR r4, [r0]

    /* +infinity is sign 0, exponent all 1s, mantissa 0 */
    LDR r5, =0x7F800000
    CMP r4, r5
    BEQ inf_pos

    /* -infinity is the same pattern with the sign bit also set */
    LDR r5, =0xFF800000
    CMP r4, r5
    BEQ inf_neg

    /* Any other bit pattern is a finite value (or NaN), so report
     * "not infinity" */
    MOV r0, 0
    B inf_done

inf_pos:
    MOV r0, 1           /* report +infinity to the caller */
    B inf_done

inf_neg:
    MOV r0, -1          /* report -infinity to the caller */

inf_done:
    /* The result code is already in r0 as the return value.
     * Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* DON'T FORGET TO FOLLOW THE CALLING CONVENTION!  */

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */

    /* Save the callee-saved registers and the return address. LR must be
     * saved because every BL below overwrites it, and asmFmax still needs
     * it to return to the C code that called it */
    PUSH {r4-r11, LR}

    /* r0 and r1 hold the two input floats, but they are argument
     * registers that the calls below will overwrite, so keep the
     * inputs safe in callee-saved registers */
    MOV r4, r0          /* r4 = bit pattern of f0 */
    MOV r5, r1          /* r5 = bit pattern of f1 */

    /* The globals keep their values between calls from C, so reset
     * every f0, f1 and fMax field to 0 before filling them in */
    BL initVariables

    /* Step 1: record the raw f0 input, then unpack it into sb0,
     * storedExp0 and realExp0. The helper returns the adjusted
     * mantissa, which is saved to mant0 */
    LDR r0, =f0
    STR r4, [r0]
    LDR r1, =sb0
    LDR r2, =storedExp0
    LDR r3, =realExp0
    BL unpackFloat
    LDR r1, =mant0
    STR r0, [r1]

    /* Step 2: same unpacking for the f1 input into the f1 fields */
    LDR r0, =f1
    STR r5, [r0]
    LDR r1, =sb1
    LDR r2, =storedExp1
    LDR r3, =realExp1
    BL unpackFloat
    LDR r1, =mant1
    STR r0, [r1]

    /* Find out whether either input is an infinity. Keep both results
     * in callee-saved registers so steps 3-6 can check them in order:
     * r6 = f0 result, r7 = f1 result (1 = +inf, -1 = -inf, 0 = neither) */
    LDR r0, =f0
    BL asmIsInf
    MOV r6, r0
    LDR r0, =f1
    BL asmIsInf
    MOV r7, r0

    /* Step 3: nothing is larger than +infinity, so f0 = +inf wins */
    CMP r6, 1
    BEQ max_is_f0

    /* Step 4: likewise, f1 = +inf wins */
    CMP r7, 1
    BEQ max_is_f1

    /* Step 5: if f0 is -infinity, f1 must be larger or the same */
    CMP r6, -1
    BEQ max_is_f1

    /* Step 6: if f1 is -infinity, f0 must be larger */
    CMP r7, -1
    BEQ max_is_f0

    /* Step 7: load both sign bits. If they differ, the positive input
     * (sign bit 0) is automatically the larger one */
    LDR r0, =sb0
    LDR r8, [r0]        /* r8 = sign of f0, reused in steps 8 and 9 */
    LDR r0, =sb1
    LDR r9, [r0]        /* r9 = sign of f1 */
    CMP r8, r9
    BEQ same_sign
    CMP r8, 0           /* signs differ: is f0 the positive one? */
    BEQ max_is_f0
    B max_is_f1

same_sign:
    /* Step 8: with matching signs, a different real exponent decides
     * which value has the bigger magnitude */
    LDR r0, =realExp0
    LDR r10, [r0]       /* r10 = real exponent of f0 (signed) */
    LDR r0, =realExp1
    LDR r11, [r0]       /* r11 = real exponent of f1 (signed) */
    CMP r10, r11
    BEQ same_exp
    CMP r8, 0           /* are both inputs positive or both negative? */
    BNE neg_exp_compare

    /* 8a: both positive, so the larger exponent is the larger value.
     * BGT is a signed compare because real exponents can be negative */
    CMP r10, r11
    BGT max_is_f0
    B max_is_f1

neg_exp_compare:
    /* 8b: both negative, so the smaller exponent is closer to 0 and
     * therefore the larger (more positive) value */
    CMP r10, r11
    BLT max_is_f0
    B max_is_f1

same_exp:
    /* Step 9: same sign and same exponent, so the mantissas decide */
    LDR r0, =mant0
    LDR r10, [r0]       /* r10 = adjusted mantissa of f0 */
    LDR r0, =mant1
    LDR r11, [r0]       /* r11 = adjusted mantissa of f1 */
    CMP r10, r11

    /* Step 10: identical sign, exponent and mantissa mean the values
     * are equal, and the instructions say to report f0 */
    BEQ max_is_f0
    CMP r8, 0           /* are both inputs positive or both negative? */
    BNE neg_mant_compare

    /* 9a: both positive, so the larger mantissa is the larger value */
    CMP r10, r11
    BGT max_is_f0
    B max_is_f1

neg_mant_compare:
    /* 9b: both negative, so the smaller mantissa is closer to 0 and
     * therefore the larger (more positive) value */
    CMP r10, r11
    BLT max_is_f0
    B max_is_f1

max_is_f0:
    /* f0 is the winner: copy all of its fields into the fMax fields */
    MOV r0, 0
    BL copyToMax
    B fmax_done

max_is_f1:
    /* f1 is the winner: copy all of its fields into the fMax fields */
    MOV r0, 1
    BL copyToMax

fmax_done:
    /* Step 11: C expects a pointer to the result, so always return the
     * address of fMax in r0. Then restore the registers saved on entry
     * (balancing the stack) and return to the C caller */
    LDR r0, =fMax
    POP {r4-r11, LR}
    BX LR


/********************************************************************
 helper: unpackFloat
    Splits one float into its pieces, following the lab's rules for
    the special exponent values, so f0 and f1 can share the same code.
    input:  r0: address of the 32b float to unpack
            r1: address to store its sign bit
            r2: address to store its stored (biased) exponent
            r3: address to store its real (unbiased) exponent
    output: r0: the adjusted mantissa (caller stores it)
********************************************************************/
unpackFloat:
    /* Save the callee-saved registers and the return address so this
     * helper follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* The calls below overwrite r0-r3, so keep the four addresses in
     * callee-saved registers for the whole unpacking process */
    MOV r4, r0          /* r4 = address of the float */
    MOV r5, r1          /* r5 = where the sign bit goes */
    MOV r6, r2          /* r6 = where the stored exponent goes */
    MOV r7, r3          /* r7 = where the real exponent goes */

    /* Extract the sign bit straight into its variable */
    MOV r0, r4
    MOV r1, r5
    BL getSignBit

    /* Extract the exponent. getExponent returns the stored exponent in
     * r0 and stored - 127 in r1 */
    MOV r0, r4
    BL getExponent
    STR r0, [r6]        /* save the stored exponent (0-255) */
    MOV r8, r0          /* keep it to apply the special-case rules below */

    /* A stored exponent of 0 means zero or a denormal number, whose real
     * exponent is defined as -126 instead of 0 - 127 */
    CMP r8, 0
    BNE save_real_exp
    MOV r1, -126

save_real_exp:
    STR r1, [r7]        /* save the real (unbiased) exponent */

    /* Extract the mantissa. getMantissa returns it without the hidden
     * bit in r0 and with the hidden bit (bit 23) set in r1 */
    MOV r0, r4
    BL getMantissa

    /* Zero, denormals (stored exponent 0) and infinity/NaN (stored
     * exponent 255) have no hidden 1, so keep the plain mantissa that is
     * already in r0 for them */
    CMP r8, 0
    BEQ unpack_done
    CMP r8, 255
    BEQ unpack_done

    /* Every other (normal) value really has the hidden 1, so return the
     * version with bit 23 set */
    MOV r0, r1

unpack_done:
    /* The adjusted mantissa is in r0 as the return value.
     * Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR


/********************************************************************
 helper: copyToMax
    Copies every field of the winning input into the fMax fields.
    input:  r0: 0 to copy the f0 fields, 1 to copy the f1 fields
    output: none (fMax, sbMax, storedExpMax, realExpMax, mantMax set)
********************************************************************/
copyToMax:
    /* Save the callee-saved registers and the return address so this
     * helper follows the ARM calling convention */
    PUSH {r4-r11, LR}

    /* Point r4-r8 at the five fields of whichever input won. The f0 and
     * f1 fields are not laid out in the same order in memory, so each
     * one is located by its own label rather than by offset */
    CMP r0, 0
    BNE copy_from_f1
    LDR r4, =f0
    LDR r5, =sb0
    LDR r6, =storedExp0
    LDR r7, =realExp0
    LDR r8, =mant0
    B copy_fields

copy_from_f1:
    LDR r4, =f1
    LDR r5, =sb1
    LDR r6, =storedExp1
    LDR r7, =realExp1
    LDR r8, =mant1

copy_fields:
    /* Copy each field of the winner into the matching fMax field, so
     * C sees the max value along with its unpacked pieces */
    LDR r9, [r4]
    LDR r10, =fMax
    STR r9, [r10]       /* raw float value of the max */

    LDR r9, [r5]
    LDR r10, =sbMax
    STR r9, [r10]       /* its sign bit */

    LDR r9, [r6]
    LDR r10, =storedExpMax
    STR r9, [r10]       /* its stored (biased) exponent */

    LDR r9, [r7]
    LDR r10, =realExpMax
    STR r9, [r10]       /* its real (unbiased) exponent */

    LDR r9, [r8]
    LDR r10, =mantMax
    STR r9, [r10]       /* its adjusted mantissa */

    /* Restore the caller's registers and return to the caller */
    POP {r4-r11, LR}
    BX LR
    
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



