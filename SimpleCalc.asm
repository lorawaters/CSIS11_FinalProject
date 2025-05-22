; Author: Lora Waters
; Simple Calculator – LC-3 Assembly
; Supports addition, subtraction, multiplication, and division on four-digit numbers

        .ORIG x3000
            
        AND R0, R0, #0              ; Clear registers R0–R6 to ensure no residual values
        AND R1, R1, #0
        AND R2, R2, #0
        AND R3, R3, #0
        AND R4, R4, #0
        AND R5, R5, #0
        AND R6, R6, #0
        ST   R0, RESULT_VAL

        LEA  R0, PROMPT_FIRST        ; Load address of first prompt string
        PUTS                         ; Display prompt
        JSR  READ_NUMBER            ; Call subroutine to read 4-digit input
        LD   R1, ACCUM              ; Load accumulated value into R1
        ST   R1, FIRST_NUM          ; Store first number in memory

        AND  R0, R0, #0             ; Clear R0 for reuse
        ST   R0, ACCUM              ; Clear accumulator
        LEA  R0, PROMPT_SECOND      ; Load address of second prompt
        PUTS                         ; Display prompt
        JSR  READ_NUMBER            ; Read second number
        LD   R2, ACCUM              ; Load second value into R2
        ST   R2, SECOND_NUM         ; Store second number

        LEA  R0, PROMPT_OPERATOR    ; Load address of operator prompt
        PUTS                         ; Display prompt
        GETC                         ; Get operator input
        OUT                          ; Echo operator
        LEA  R3, OP_SYMBOLS         ; Load base address of operator table
        STR  R0, R3, #0             ; Store operator in OP_SYMBOLS[0]

        LD   R1, FIRST_NUM          ; Load operand1 into R1
        LD   R2, SECOND_NUM         ; Load operand2 into R2
        AND  R6, R6, #0             ; Clear result register
        LEA  R5, OP_SYMBOLS         ; R5 → operator table

        ; Check for '+'
        LDR  R3, R5, #0             ; R3 = -(ASCII '+')
        ADD  R4, R0, R3            ; subtract '+' from input
        BRz  DO_ADD                 ; if zero, go to addition

        ; Check for '-'
        LDR  R3, R5, #1             ; R3 = -(ASCII '-')
        ADD  R4, R0, R3
        BRz  DO_SUBTRACT            ; branch if '-'

        ; Check for '*'
        LDR  R3, R5, #2             ; R3 = -(ASCII '*')
        ADD  R4, R0, R3
        BRz  DO_MULTIPLY            ; branch if '*'

        ; Check for '/'
        LDR  R3, R5, #3             ; R3 = -(ASCII '/')
        ADD  R4, R0, R3
        BRz  DO_DIVIDE              ; branch if '/'

        ; If no valid operator, halt program
        HALT

DO_ADD
        ADD  R6, R1, R2            ; R6 = operand1 + operand2
        JSR  SHOW_RESULT           ; Display result

DO_SUBTRACT
        NOT  R2, R2                ; Two's complement: negate second operand
        ADD  R2, R2, #1
        ADD  R6, R1, R2            ; R6 = operand1 - operand2
        JSR  SHOW_RESULT           ; Display result

DO_MULTIPLY
        AND  R6, R6, #0            ; Clear product accumulator
        ADD  R4, R2, #0            ; R4 = counter (operand2)
MULT_LOOP
        BRz  MULT_DONE             ; If counter==0, done
        ADD  R6, R6, R1            ; product += operand1
        ADD  R4, R4, #-1           ; counter--
        BRnzp MULT_LOOP            ; Repeat loop
MULT_DONE
        JSR  SHOW_RESULT           ; Display result

DO_DIVIDE
        AND  R6, R6, #0            ; Clear quotient accumulator
        ADD  R4, R1, #0            ; R4 = remainder (operand1)
DIV_LOOP
        NOT  R5, R2                ; R5 = -operand2
        ADD  R5, R5, #1
        ADD  R5, R4, R5            ; R5 = remainder - operand2
        BRn  DIV_END               ; If negative, division done
        ADD  R4, R5, #0            ; Update remainder
        ADD  R6, R6, #1            ; Increment quotient
        BRnzp DIV_LOOP             ; Continue dividing
DIV_END
        JSR  SHOW_RESULT           ; Display quotient

SHOW_RESULT
        LEA  R0, MSG_RESULT        ; Load result message
        PUTS                        ; Print message
        ST   R6, RESULT_VAL        ; Store numeric result
        JSR  CALC_STRING_LENGTH    ; Determine how many digits
        JSR  NUMBER_TO_ASCII       ; Convert number to ASCII in buffer
        ADD  R6, R6, #0            ; Restore pointer to buffer start
        BRn  PRINT_NEG_SIGN        ; If negative, print '-'
        LEA  R0, OUTPUT_BUFFER     ; Load address of output buffer
        PUTS                        ; Print ASCII digits
        HALT                        ; End program

PRINT_NEG_SIGN
        ST   R7, SAVED_R7          ; Save return address
        NOT  R6, R6                ; Make result positive
        ADD  R6, R6, #1
        LEA  R0, NEG_SYMBOL        ; Load '-' symbol
        PUTS                        ; Print '-'
        LD   R7, SAVED_R7          ; Restore return address
        RET                         ; Return to caller

READ_NUMBER
        ST   R7, SAVED_R7          ; Save return address
        LEA  R3, INPUT_BUFFER      ; R3 → input array
        AND  R4, R4, #0            ; char count = 0
        AND  R5, R5, #0            ; temp index = 0
READ_CHAR_LOOP
        GETC
        ADD  R6, R0, #-10          ; check for Enter key
        BRz  DONE_READ             ; if Enter, stop reading
        OUT                        ; echo digit
        STR  R0, R3, #0            ; store ASCII char
        ADD  R4, R4, #1            ; increment count
        ST   R4, INPUT_SIZE        ; save count
        ADD  R3, R3, #1            ; advance buffer pointer
        ADD  R5, R4, #-4           ; compare count to 4
        BRn  READ_CHAR_LOOP        ; loop until four digits read
DONE_READ
        LEA  R3, INPUT_BUFFER      ; reset pointer to start
        LEA  R4, PLACE_VALUES      ; pointer to place values array
        LD   R5, NEG_ASCII_ZERO    ; offset to convert ASCII to integer
        LD   R6, INPUT_SIZE        ; number of chars read
        ADD  R6, R6, #-1           ; index = size-1
DIGIT_PROCESS_LOOP
        LDR  R1, R3, #0            ; load ASCII char
        ADD  R1, R1, R5            ; convert char to integer
        ADD  R2, R4, R6            ; select correct multiplier
        LDR  R2, R2, #0            ; load place value
        JSR  MULTIPLY_CONST        ; compute digit * place
        LD   R1, RESULT_VAL        ; load multiplication result
        LD   R0, ACCUM             ; load current ACCUM
        ADD  R0, R0, R1            ; add to accumulator
        ST   R0, ACCUM             ; store back
        ADD  R3, R3, #1            ; next char
        ADD  R6, R6, #-1           ; decrement index
        BRzp DIGIT_PROCESS_LOOP    ; repeat for all digits
        LD   R7, SAVED_R7          ; restore return address
        RET                         ; return with ACCUM set

MULTIPLY_CONST
        ST   R6, SAVED_R6          ; save registers
        ST   R4, SAVED_R4
        AND  R6, R6, #0            ; product = 0
        AND  R4, R4, #0            ; counter = 0
MULT_CONST_LOOP
        ADD  R6, R6, R1            ; add digit
        ADD  R4, R4, #-1           ; decrement counter
        BRp  MULT_CONST_LOOP       ; loop until counter=0
        ST   R6, RESULT_VAL        ; store product
        LD   R4, SAVED_R4          ; restore registers
        LD   R6, SAVED_R6
        RET                         ; return with RESULT_VAL

CALC_STRING_LENGTH
        ST   R7, SAVED_R7
        LD   R1, RESULT_VAL        ; number to measure
        LEA  R3, PLACE_VALUES
        AND  R4, R4, #0
        ADD  R4, R4, #4            ; start with highest index
LENGTH_LOOP
                ADD  R2, R3, R4    ; compute address of place value
        LDR  R2, R2, #0    ; load place value            ; load place value
        ST   R4, SAVED_R4
        ST   R3, SAVED_R3
        JSR  DIVIDE_LOOP           ; divide by place value
        LD   R4, SAVED_R4
        LD   R3, SAVED_R3
        ADD  R6, R6, #0            ; update quotient
        BRp  LEN_DONE              ; if quotient>0, found length
        ADD  R4, R4, #-1           ; else decrease index
        BRnzp LENGTH_LOOP          ; repeat
LEN_DONE
        ADD  R4, R4, #1            ; length = index+1
        ST   R4, STRING_LENGTH     ; store length
        LD   R7, SAVED_R7
        RET                         ; return

NUMBER_TO_ASCII
        ST   R7, SAVED_R7
        LEA  R6, OUTPUT_BUFFER     ; buffer pointer
        LD   R3, STRING_LENGTH     ; number of digits
ASCII_CONVERT_LOOP
        LEA  R5, PLACE_VALUES
        ADD  R3, R3, #-1
        ADD  R5, R5, R3            ; select place value
        LDR  R2, R5, #0            ; load divisor
        LD   R1, RESULT_VAL
        ST   R3, SAVED_R3
        ST   R4, SAVED_R4
        ST   R5, SAVED_R5
        ST   R6, SAVED_R6
        JSR  DIVIDE_LOOP           ; quotient in QUOTIENT, remainder in REMAINDER
        LD   R3, SAVED_R3
        LD   R4, SAVED_R4
        LD   R5, SAVED_R5
        LD   R6, SAVED_R6
        LD   R0, QUOTIENT          ; load digit
                LD   R1, ASCII_0   ; load ASCII '0'
        ADD  R0, R0, R1     ; convert digit to ASCII       ; convert to ASCII
        STR  R0, R6, #0            ; store in buffer
        ADD  R6, R6, #1            ; advance buffer
        LD   R5, REMAINDER         ; update RESULT_VAL for next digit
        ST   R5, RESULT_VAL
        BRp  ASCII_CONVERT_LOOP    ; repeat for all digits
        LD   R7, SAVED_R7
        RET                         ; return

DIVIDE_LOOP
        AND  R3, R3, #0            ; clear remainder
        ADD  R3, R1, #0            ; remainder = dividend
        AND  R4, R4, #0            ; clear counter
        ADD  R4, R2, #0            ; divisor
        AND  R6, R6, #0            ; quotient=0
        NOT  R4, R4
        ADD  R4, R4, #1            ; prepare -divisor
DIV_LOOP2
        ADD  R3, R3, R4            ; remainder - divisor
        BRn  DIV_END2              ; if negative, done
        ADD  R6, R6, #1            ; increment quotient
        BRnzp DIV_LOOP2            ; keep subtracting
DIV_END2
        ST   R6, QUOTIENT          ; store quotient
        ST   R3, REMAINDER         ; store remainder
        RET                         ; return


FIRST_NUM        .FILL   #0        ; storage for first input
SECOND_NUM       .FILL   #0        ; storage for second input
RESULT_VAL       .FILL   #0        ; storage for final result
ACCUM            .FILL   #0        ; accumulator for READ_NUMBER

INPUT_BUFFER     .BLKW   #5        ; buffer to hold typed digits
INPUT_SIZE       .FILL   #0        ; count of digits read
PLACE_VALUES     .FILL   #1        ; place-value array: 1,10,100,1000,10000
                 .FILL   #10
                 .FILL   #100
                 .FILL   #1000
                 .FILL   #10000
NEG_ASCII_ZERO   .FILL   x-30      ; offset to convert ASCII->integer

OP_SYMBOLS       .FILL   #-43     ; table of negative ASCII codes for '+','-','*','/'
                 .FILL   #-45
                 .FILL   #-42
                 .FILL   #-47

PROMPT_FIRST     .STRINGZ "\nEnter first number: "
PROMPT_SECOND    .STRINGZ "\nEnter second number: "
PROMPT_OPERATOR  .STRINGZ "\nEnter operator (+-*/): "
MSG_RESULT       .STRINGZ "\nResult = "
OUTPUT_BUFFER    .BLKW   #5        ; buffer for ASCII digits
NEG_SYMBOL       .STRINGZ "-"      ; negative sign

ASCII_0          .FILL   #48       ; ASCII code for '0'

STRING_LENGTH    .FILL   #0        ; number of digits in result
QUOTIENT         .FILL   #0        ; temp for division
REMAINDER        .FILL   #0        ; temp for division

SAVED_R3         .FILL   #0        ; save spaces for subroutines
SAVED_R4         .FILL   #0
SAVED_R5         .FILL   #0
SAVED_R6         .FILL   #0
SAVED_R7         .FILL   #0

        .END
