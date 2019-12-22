    ; Reset Vector
    ORG   00H
    JMP   MAIN

;====================================================================
; DEFINITIONS
;====================================================================

    ; Transistors
    TRN1		EQU	P2.0
    TRN2		EQU	P2.1
    TRN3		EQU	P2.2
    TRN4		EQU	P2.3

    ; 7 Segment SEGPORTs
    SEGPORT	EQU P0

    ; Buttons (Queue/Service)
    BUTTONQ	EQU P1.0
    BUTTONS	EQU P1.1

;====================================================================
; CODE SEGMENT
;====================================================================

MAIN:      	
    MOV DPTR, #NUMVAL
    MOV R3, #00H
    MOV R0, #07
    MOV R1, #06
    MOV R2, #03
    MOV R3, #04

D0:          	
    MOV  P2, #00H
    SETB TRN1             
    MOV A, R0
    ACALL UPDATE

    MOV P2, #00H              
    SETB TRN2		 
    MOV A, R1
    ACALL UPDATE

    MOV P2, #00H              
    SETB TRN3		 
    MOV A, R2
    ACALL UPDATE

    MOV P2, #00H              
    SETB TRN4		 
    MOV A, R3
    ACALL UPDATE

    LJMP MAIN

UPDATE: 	
    MOVC A, @A+DPTR		; Pushing data to Port 0 for lighting up the LEDs     
    MOV SEGPORT, A
    CLR A
    ACALL DELAY
    RET

DELAY:      
    MOV R5, #90H      		; Delay loop (for software multiplexing)

LOOP:        
    MOV R4, #0FFH
    DJNZ R4, $
    DJNZ R5, LOOP
    RET

ORG 200H

NUMVAL:   
    ;DB 0C0H, 0F9H,24H,0B0H,99H,12H,02H,0F8H,00H,10H ;Common Anode
    DB 03FH, 006H, 05BH, 04FH, 066H, 06DH, 07DH, 007H, 07FH, 067H ; Common Cathode 

END
