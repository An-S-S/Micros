;*********************************************************
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Laboratorio 03: Interrupciones
;
; Author : Eduardo André Sosa Sajquim
; Proyecto: Interrupciones
; Hardware: ATMega328P
; Creado: 21/febrero/2025
; Modificado: 27/02/2025
; Descripción: Multiples contadores con distintas interrupciones
;*********************************************************
.include "M328PDEF.inc"
.DSEG
bin_cnt:   .byte 1         ; Contador binario de 4 bits (0–15)
units:     .byte 1         ; Contador de unidades (0–9)
tens:      .byte 1         ; Contador de decenas (0–5)
.CSEG
.DEF __zero_reg__ = R1  
.org 0x0000
    RJMP PILA          
.org 0x0020
    RJMP TIMER0_ISR
.org 0x0028
    RJMP PCINT_ISR
LISTA: .db 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90
;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;								C ó d i g o
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________


;______________________________________________________________________________
; Configuración inicial
;______________________________________________________________________________
PILA:
    ; Configurar puntero de pila
    LDI     R16, LOW(RAMEND)
    OUT     SPL, R16
    LDI     R16, HIGH(RAMEND)
    OUT     SPH, R16
	;_________________________________________________________
    CLR     __zero_reg__
	;_________________________________________________________
    ; Inicializar variables en RAM a 0
    LDI     R16, 0
    STS     bin_cnt, R16
    STS     units,   R16
    STS     tens,    R16
	;_________________________________________________________
    ; Configurar PORTB para contador binario 
    LDI     R16, 0x0F
    OUT     DDRB, R16
	;_________________________________________________________
    ; Configurar PORTD como salida 7 segmentos
    LDI     R16, 0xFF
    OUT     DDRD, R16
	;_________________________________________________________
    ; Configurar PORTC para los pushbuttons:
    LDI     R16, 0x03
    OUT     PORTC, R16
	;_________________________________________________________
    ; Habilitar la interrupción por cambio en PORTC: PCINT[14:8]
    LDI     R16, (1<<PCIE1)
    STS     PCICR, R16
    LDI     R16, (1<<PCINT8) | (1<<PCINT9)
    STS     PCMSK1, R16
	;_________________________________________________________


	;_________________________________________________________
    ; Habilitar interrupción por overflow en Timer0
    LDI     R16, (1<<TOIE0)
    STS     TIMSK0, R16
    ; Limpiar bandera de overflow
    LDI     R16, (1<<TOV0)
    STS     TIFR0, R16
	;_________________________________________________________
    ; Configurar el prescaler del Timer0:
    LDI     R16, (1<<CLKPCE)
    STS     CLKPR, R16           ; Habilitar cambio de CLKPR
    LDI     R16, 0b00000100
    STS     CLKPR, R16
    LDI     R16, (1<<CS01) | (1<<CS00)
    OUT     TCCR0B, R16
	;_________________________________________________________
    ; Cargar valor inicial del Timer0 
    LDI     R16, 0x6F
    OUT     TCNT0, R16
	;_________________________________________________________
    ; Inicializar registros usados en el multiplexado del display:
    LDI     R18, 0          ; Contador de ticks
    LDI     R20, 0          ; Variable auxiliar para el multiplexado
    LDI     R21, 0          ; Estado de dígito a mostrar
	;_________________________________________________________
    SEI                     ; Habilitar interrupciones globalmente
;______________________________________________________________________________


;______________________________________________________________________________
MAIN:
    RJMP MAIN             ; Bucle infinito
;______________________________________________________________________________


;______________________________________________________________________________
TIMER0_ISR:
    ; Guardar registros usados en la ISR
    PUSH    R16
    PUSH    R17
    PUSH    R18
    PUSH    R20
    PUSH    R21
    PUSH    R24
    PUSH    R25
    PUSH    R30
    PUSH    R31
	;_________________________________________________________
    SBI     TIFR0, TOV0     ; Limpiar bandera de overflow
    LDI     R16, 0x6F
    OUT     TCNT0, R16
	;_________________________________________________________
    INC     R18             ; Incrementa contador de ticks
    CPI     R18, 30
    BRNE    SKIP_7SEG_UPDATE
	;_________________________________________________________
    LDI     R18, 0          ; Reinicia contador de ticks
	;_________________________________________________________
    LDS     R24, units      ; Actualiza unidades
    INC     R24
    CPI     R24, 10
    BRNE    UPDATE_UNITS
    LDI     R24, 0
    LDS     R25, tens
    INC     R25
    CPI     R25, 6          ; Si llegan a 6 (60 s), reinicia decenas
    BRNE    STORE_TENS
    LDI     R25, 0
;______________________________________________________________________________


;______________________________________________________________________________
STORE_TENS:
    STS     tens, R25
;______________________________________________________________________________


;______________________________________________________________________________
UPDATE_UNITS:
    STS     units, R24
	;_________________________________________________________
    ; Actualizar patrón para las unidades
    LDI     R30, low(LISTA)
    LDI     R31, high(LISTA)
    LDS     R25, units
    ADD     R30, R25
    ADC     R31, __zero_reg__
    LPM     R17, Z+
	;_________________________________________________________
    ; Actualizar patrón para las decenas
    LDI     R30, low(LISTA)
    LDI     R31, high(LISTA)
    LDS     R25, tens
    ADD     R30, R25
    ADC     R31, __zero_reg__
    LPM     R22, Z+
;______________________________________________________________________________


;______________________________________________________________________________
SKIP_7SEG_UPDATE:
    LDI     R16, 0x01
    EOR     R21, R16        ; Alterna entre 0 y 1 para multiplexado
    TST     R21
    RJMP    SHOW_UNITS
;______________________________________________________________________________


;______________________________________________________________________________
SHOW_TENS:
    OUT     PORTD, R22      ; Muestra decenas
    RJMP    END_TIMER_ISR
;______________________________________________________________________________
SHOW_UNITS:
    OUT     PORTD, R17      ; Muestra unidades
	ret
;______________________________________________________________________________


;______________________________________________________________________________
END_TIMER_ISR:             ; Restaurar registros
    POP     R31
    POP     R30
    POP     R25
    POP     R24
    POP     R21
    POP     R20
    POP     R18
    POP     R17
    POP     R16
    RETI
;______________________________________________________________________________


;______________________________________________________________________________
PCINT_ISR:
    PUSH    R16
    PUSH    R17
	IN      R16, PINC
	;_________________________________________________________
    ; Verificar botón de incremento
    MOV     R17, R16
    ANDI    R17, 0x01      ; Extrae bit0
    CPI     R17, 0
    BRNE    CHECK_PB1      ; Si no es 0, salta
    LDS     R17, bin_cnt
    INC     R17
    LDI     R16, 0x0F
    AND     R17, R16       ; Limitar a 4 bits
    STS     bin_cnt, R17
    IN      R16, PORTB
    ANDI    R16, 0xF0
    OR      R16, R17
    OUT     PORTB, R16
;______________________________________________________________________________


;______________________________________________________________________________
CHECK_PB1:
    ; Verificar botón de decremento (PC1)
    IN      R16, PINC
    MOV     R17, R16
    ANDI    R17, 0x02      ; Extrae bit1
    CPI     R17, 0
    BRNE    END_PCINT      ; Si no es 0, no se presionó
    LDS     R17, bin_cnt
    CP      R17, __zero_reg__
    BRNE    DEC_NORMAL
    LDI     R17, 15        ; Si era 0, se envuelve a 15
    RJMP    STORE_BIN
;______________________________________________________________________________

;______________________________________________________________________________
DEC_NORMAL:
    DEC     R17
;______________________________________________________________________________


;______________________________________________________________________________
STORE_BIN:
    STS     bin_cnt, R17
    IN      R16, PORTB
    ANDI    R16, 0xF0
    OR      R16, R17
    OUT     PORTB, R16
;______________________________________________________________________________


;______________________________________________________________________________
END_PCINT:
    POP     R17
    POP     R16
    RETI
;______________________________________________________________________________