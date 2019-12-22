        ORG   00H
        JMP   MAIN

MAIN: 	MOV SCON, #52H			; 8-bit UART Mode 1, REN enabled, Timer 1 is set ready
        MOV TMOD, #21H			; Enables Timer 1 (M1)/Timer 0 (M0)
        MOV TH1, #0FDH			; Sets the appropriate value (related to baud rate at 11.0592MHz)
        ANL	PCON, #7FH 			; Clear SMOD (to make sure that it won't affect the baud rate)
        SETB TR1				; Enables Timer 1 (UART)
        MOV P1, #07H
        MOV R0, #00H		; Default queue number
        MOV R1, #00H		; Default service number
        MOV R6, #00H
        MOV R2, #1		; Queue button debouncing flag
        MOV R3, #1		; Service increment button debouncing flag
        MOV R4, #1		; Service decrement button debouncing flag
        ACALL UART

BUT1:	JB P1.0, BUT2			; Check if the button has been pressed
        CJNE R2, #1, BUT2		; If the button has already been pressed (FLAG - 1), jump to the next button subroutine

        MOV R2, #0				; Set FLAG - 0 to indicate that the button is being pressed
        MOV A, R0				; Move the queue number register to the accumulator
        ADD A, #01H				; Add the value in the accumulator with #01H
        DA A					; Adjust the value to the next closest Binary Encoded Decimal (BCD) and store it in the accumulator
        MOV R0, A				; Move the value stored in the accumulator back to the queue number register

        CALL UART				; Send the values to Ubidots

BUT2:	JB P1.1, BUT3			; Check if the button has been pressed
        CJNE R3, #1, BUT3		; If the button has already been pressed (FLAG - 1), jump to the next button subroutine

        MOV A, R0				; Move the queue number register to the accumulator
        XRL A, R1				; Perform a bitwise XOR operation between the value stored in the accumulator with the service value register
        JZ BUT3					; If the value in the accumulator is 0 (queue number = service number), jump directly to the next button subroutine

        MOV R5, #15				; If not, set the timer duration for the buzzer to be activated
        SETB P1.3				; Activate the buzzer

        MOV R3, #0				; Set FLAG - 0 to indicate that the button is being pressed
        MOV A, R1				; Move the service number register to the accumulator
        ADD A, #01H				; Add the value in the accumulator with #01H
        DA A					; Adjust the value to the next closest Binary Encoded Decimal (BCD) and store it in the accumulator
        MOV R1, A				; Move the value stored in the accumulator back to the queue number register

        CALL RANDNUMGEN			; Calls for the random number generator subroutine to be called
        CALL UART				; Sends the values to Ubidots

BUT3:	JB P1.2, MULTPLX		; Check if the button has been presseds
        CJNE R4, #1, MULTPLX	; If the button has already been pressed (FLAG - 1), jump to the next button subroutine

        MOV R4, #0				; Set FLAG - 0 to indicate that the button is being pressed
        MOV A, R1				; Move the service number register to the accumulator
        MOV B, A				; Move the value stored in the accumulator in the B register
        ADD A, #99H				; "Subtract" the value stored in the accumulator by #01H
        DA A					; Adjust the value to the next closest Binary Encoded Decimal (BCD) and store it in the accumulator
        MOV R1, A				; Move the value stored in the accumulator back to the queue number register

        MOV R5, #15				; Set the timer duration for the buzzer to be activatetd
        SETB P1.3				; Activate the buzzer

        JC BUT3_FIN				; Jump if the new value of R1 is lesser than 0
        MOV A, B				; Move the value stored in the B register back to the accumulator
        MOV R1, A				; Restore the value of the accumulator back to its previous value

BUT3_FIN:
        CALL UART				; Send the values to Ubidots regardless of the carry bit sett

MULTPLX:	
        MOV P2, #00H			; Turn off all the 7-segment displays
        SETB P2.0				; Turn on the first 7-segment (queue number - units)
        MOV A, R0				; Move the queue number register value into the accumulator
        MOV B, A				; Move the value stored in the accumulator into the B register
        CALL LOWERNIB			; Fetch the lower nibble of the value stored in the accumulator
        ACALL UPDATE			; Send the lower nibble data to the 7-segment to be displayed

        MOV P2, #00H			; Turn off all the 7-segment displays             
        SETB P2.1				; Turn on the second 7-segment (queue number - tens)
        MOV A, B				; Restore the original value stored in the accumulator
        CALL UPPERNIB			; Fetch the upper nibble of the value stored in the accumulator
        ACALL UPDATE			; Send the upper nibble data to the 7-segment to be displayed

        MOV P2, #00H			; Turn off all the 7-segment displays            
        SETB P2.2				; Turn on the third 7-segment (counter number)
        MOV A, R6				; Move the counter number value into the accumulator
        ACALL UPDATE			; Send the value to the 7-segment to be displayed

        MOV  P2, #00H			; Turn off all the 7-segment displays         
        SETB P2.3				; Turn on the fourth 7-segment (service number - units)
        MOV A, R1				; Move the service number register value into the accumulator
        MOV B, A				; Move the value stored in the accumulator into the B register
        CALL LOWERNIB			; Fetch the lower nibble of the value stored in the accumulator
        ACALL UPDATE			; Send the lower nibble data to the 7-segment to be displayed

        MOV P2, #00H			; Turn off all the 7-segment displays               
        SETB P2.4				; Turn on the fifth 7-segment (service number - tens)
        MOV A, B				; Restore the original value stored in the accumulator
        CALL UPPERNIB			; Fetch the upper nibble of the value stored in the accumulator
        ACALL UPDATE			; Send the upper nibble data to the 7-segment to be displayed

        DJNZ R5, BUT1FLAG		; Additive timer for the buzzer, will loop for around 0.5s-1s
        CLR P1.3				; Disable the buzzer once the time is over

BUT1FLAG:
        JNB P1.0, BUT2FLAG		; Check if the button has been depressed
        MOV R2, #1				; If yes, then set FLAG - 0

BUT2FLAG:
        JNB P1.1, BUT3FLAG		; Check if the button has been depressed
        MOV R3, #1				; If yes, then set FLAG - 0

BUT3FLAG:
        JNB P1.2, ADDRESS_LIMIT_BYPASS	; Check if the button has been depressed
        MOV R4, #1				; If yes, then set FLAG - 0
        LJMP BUT1				; Jump to the top of the code unconditionally

ADDRESS_LIMIT_BYPASS:
        LJMP BUT1				; Jump to the top of the code unconditionally (since jumping from JNB at this point would not work)

UPDATE: 
        MOV DPTR, #SEGLT		; Load the 7-segment encoded hex lookup table to the data pointer
        MOVC A, @A+DPTR			; Find the appropriate encoded hex to be sent to the 7-segment     
        MOV P0, A				; The encoded hex is pushed to be shown on the 7-segment
        MOV TH0, #0EFH			; Store Timer 0 runtime details
        MOV TL0, #000H			; Store Timer 0 runtime details
        SETB TR0				; Enable Timer 0
        RET

DELAY:	JNB TF0, DELAY			; Once Timer 0 is enabled, keep looping till overload
        CLR TR0					; Clear Timer runtime details
        CLR TF0					; Clear Timer runtime details
        RET

LOWERNIB:
        ANL A, #0FH				; Find the bits 0-3
        RET

UPPERNIB:
        SWAP A					; Swap bits 0-3 with bits 4-7
        ANL A, #0FH				; Find the newly replaced bits 0-3
        RET

RANDNUMGEN:
        ACALL RAN1				; Generate the random number
        MOV A, R6				; Move the counter number value to the accumulator
        CALL LOWERNIB			; Find the lower nibble of the value
        DA A					; Correct the hex to the nearest Binary Encoded Decimal (BCD)
        MOV R6, A				; Move the corrected value in the accumulator back in the counter number register
        RET

RAN1:  	MOV A, R6			
        JNZ RAN2				; Jump if the accumulator is not set (A == 0)
        CPL A					; Change A = 0 to A = 1
        MOV R6, A				; Move 1 into R6

RAN2:	ANL A, #10111000B		; Perform XOR operation 
        MOV C, P				; Find whether the value stored in the accumulator has an even or odd parity
        MOV A, R6				; Move R6 into accumulator
        RLC A					; Move bit 0 to bit 7 with carry bit
        MOV R6, A				; Move the accumulator value back into R6
        RET

UART:	MOV A, R0
        MOV B, A
        ACALL UPPERNIB
        ADD A, #30H
        ACALL SEND
        MOV A, B
        ACALL LOWERNIB
        ADD A, #30H
        ACALL SEND

        MOV A, #','
        ACALL SEND

        MOV A, R1
        MOV B, A
        ACALL UPPERNIB
        ADD A, #30H
        ACALL SEND
        MOV A, B
        ACALL LOWERNIB
        ADD A, #30H
        ACALL SEND

        MOV A, #','
        ACALL SEND

        MOV A, R6
        ADD A, #30H
        ACALL SEND

        MOV A, #0AH
        ACALL SEND
        RET

SEND:	JNB TI, SEND	; Serial transmission subroutine for UART functionality
        CLR TI
        MOV SBUF, A
        CLR A
        RET

ORG 	200H
SEGLT:   
        ;DB 0C0H, 0F9H,24H,0B0H,99H,12H,02H,0F8H,00H,10H ;Common Anode
        DB 03FH, 006H, 05BH, 04FH, 066H, 06DH, 07DH, 007H, 07FH, 067H ; Common Cathode 

        END
