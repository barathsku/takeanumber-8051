        ORG   00H
        JMP   MAIN

MAIN: 	
        MOV TMOD, #01H		; Enable timer 0 (M0)
        MOV P1, #07H            ; 7-segment common port
        MOV R0, #00H		; Default queue number
        MOV R1, #00H		; Default service number
        MOV R2, #1		; Queue button debouncing flag
        MOV R3, #1		; Service increment button debouncing flag
        MOV R4, #1		; Service decrement button debouncing flag

BUT1:	; Queue button debouncing check
        JB P1.0, BUT2
        CJNE R2, #1, BUT2
        
        MOV R2, #0
        MOV A, R0
        ADD A, #01H
        DA A
        MOV R0, A

BUT2:	; Service button (increment) debouncing check
        JB P1.1, BUT3
        CJNE R3, #1, BUT3

        ; if(service_no == queue_no){ jump_to_next_branch; } else { proceed; }
        MOV A, R0
        XRL A, R1
        JZ BUT3	

        ; Activate the buzzer for a short time
        MOV R5, #15
        SETB P1.3

        ; Make sure hex increment goes from 9 to 10, not 9 to A (and so on)
        MOV R3, #0
        MOV A, R1
        ADD A, #01H
        DA A                    ; This is a shit way of hex->BCD conversion, use manual ADD instruction instead
        MOV R1, A

BUT3:	; Service button (decrement) debouncing check
        JB P1.2, MULTPLX
        CJNE R4, #1, MULTPLX
        
        ; if(service_no != 0) { decrement; } else { do_nothing; }
        MOV R4, #0
        MOV A, R1
        MOV B, A
        ADD A, #99H             ; If the carry bit is set, then the value stored in the accumulator before executing this instruction
                                ; is 0. There is probably a better way of doing this, feel free to amuse me (and yourself)
        DA A                    ; This is a shit way of hex->BCD conversion, use manual ADD instruction instead
        MOV R1, A
        
        ; Activate the buzzer for a short time
        MOV R5, #15				
        SETB P1.3				

        ; if(service_no < 0) { set_previous_value; } (the value doesn't actually go below 0 in assembly, for this case
        ; decrementing 0 in hex will only go back to 99H because of how the instruction set in MCS-51 was designed to operate)
        JC MULTPLX
        MOV A, B
        MOV R1, A

MULTPLX:
        ; First segment
        MOV P2, #00H
        SETB P2.0
        MOV A, R0
        MOV B, A
        CALL LOWERNIB
        ACALL UPDATE			; Display queue number lower nibble to 7-segment

        ; Second segment
        MOV P2, #00H        
        SETB P2.1
        MOV A, B
        CALL UPPERNIB
        ACALL UPDATE			; Display queue number upper nibble to 7-segment

        ; Third segment
        MOV  P2, #00H 
        SETB P2.3
        MOV A, R1
        MOV B, A
        CALL LOWERNIB
        ACALL UPDATE			; Display service number lower nibble to 7-segment

        ; Fourth segment
        MOV P2, #00H             
        SETB P2.4
        MOV A, B
        CALL UPPERNIB
        ACALL UPDATE                    ; Display service number upper nibble to 7-segment

        ; The part where the buzzer gets disabled
        DJNZ R5, BUT1FLAG
        CLR P1.3

        ; BUTTON FLAG CHECKS
BUT1FLAG:
        JNB P1.0, BUT2FLAG
        MOV R2, #1

BUT2FLAG:
        JNB P1.1, BUT3FLAG
        MOV R3, #1

BUT3FLAG:
        JNB P1.2, ADDRESS_LIMIT_BYPASS
        MOV R4, #1
        LJMP BUT1

ADDRESS_LIMIT_BYPASS:
        LJMP BUT1

UPDATE: ; Update the 7-segment with the values
        MOV DPTR, #SEGLT
        MOVC A, @A+DPTR
        MOV P0, A
        MOV TH0, #0EFH
        MOV TL0, #000H
        SETB TR0
        RET

DELAY:	; Timer 0 delay for 7-segment multiplexing, too lazy to do calculation for additive timer
        JNB TF0, DELAY
        CLR TR0
        CLR TF0
        RET

        ; 42, upper nib = 4 and lower nib = 2
LOWERNIB:
        ANL A, #0FH				; Find the bits 0-3
        RET

UPPERNIB:
        SWAP A					; Swap bits 0-3 with bits 4-7
        ANL A, #0FH				; Find the newly replaced bits 0-3
        RET        

ORG 	200H
SEGLT:   
        ;DB 0C0H, 0F9H,24H,0B0H,99H,12H,02H,0F8H,00H,10H ;Common Anode
        DB 03FH, 006H, 05BH, 04FH, 066H, 06DH, 07DH, 007H, 07FH, 067H ; Common Cathode 

        END
