;*********************************************************
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Laboratorio : 
;
; Author : Eduardo André Sosa Sajquim
; Proyecto: Reloj
; Hardware: ATMega328P
; Creado: 28/febrero/2025
; Modificado:XX/XX/2025
; Descripción: 
;*********************************************************

;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;						 I N I C I A L I Z A C I Ó N
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________

;______________________________________
.include "m328pdef.inc"
; Definiciones
.equ LCD_RS = 4
.equ LCD_EN = 5
.equ LCD_D4 = 0
.equ LCD_D5 = 1
.equ LCD_D6 = 2
.equ LCD_D7 = 3
;______________________________________

;______________________________________
.def temp = r16
.def estados = r17
.def un_hora = r18 
.def dec_hora = r19        
.def un_min = r20      
.def dec_min = r21
.def contador = r22
.def horas_totales = r23
.def display = r24 
.def dias = r25
.def meses = r15
.def QDis = r14
Tabla:
	.db 0 == 0b00111111 ; 0
    .db 1 == 0b00000110 ; 1
    .db 2 == 0b01011011 ; 2
    .db 3 == 0b01001111 ; 3
    .db 4 == 0b01100110 ; 4
    .db 5 == 0b01101101 ; 5
    .db 6 == 0b01111101 ; 6
    .db 7 == 0b00000111 ; 7
    .db 8 == 0b01111111 ; 8
    .db 9 == 0b01101111 ; 9
;______________________________________


;______________________________________
.dseg
hora_buffer: .byte 9     ; Buffer para "HH:MM:SS" + terminador
;______________________________________


;______________________________________
.cseg
.org 0x0000
    rjmp INICIO
;______________________________________
INICIO:
    ; Configurar pila
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

	; Limpiando variables
	clr temp
	clr estados
	clr un_hora
	clr dec_hora
	clr un_min
	clr dec_min
	clr conteo 
	clr display

    ; Configurar pines C como salida [Display]
	// [0111 1111] <- Displays (PC0 - PC5)
	// [1000 0000] <- Buzzer (PC6)
    ldi temp, 0xFF
    out DDRC, temp
	clr temp

	; Configurar pines B como salida [Leds y Alarma]
	// [0000 0XXX] <- Leds (PB0 - PB2)
	// [--0X X000] <- Configurar 2 últimos displays (PB3 - PB4)
	ldi temp, 0xFF
	out DDRB, temp
	clr temp
	
	; Configurar pines D como entradas [Botones]
	// [0000 01--] <- Confirmación (PD2)
	// [0000 10--] <- Estados      (PD3)
	// [0001 00--] <- Aumento      (PD4)
	// [0010 00--] <- Disminución  (PD5)
	ldi temp, 0b11000000 // Configurar 
	// [1100 0000] <- Configurar 2 primeros displays (PD6 - PD7)
	out DDRD, temp
	clr temp

    ; Configurar Timer1 para 1 segundo (16 MHz / 256 / 62500 = 1 Hz)
    ldi temp, 0x00
    sts TCCR1A, temp     ; Modo normal
    ldi temp, 0x05       ; Prescaler 1024
    sts TCCR1B, temp
    ldi temp, high(62500) ; Valor inicial para 1 segundo
    sts TCNT1H, temp
    ldi temp, low(62500)
    sts TCNT1L, temp
    ldi temp, (1<<TOIE1) ; Habilitar interrupción por overflow
    sts TIMSK1, temp
	clr temp

	; Configurar Timer0 para 500ms (Leds indicadores de segundo) ?? :(
    ldi     temp, (1 << TOIE0)
    sts     TIMSK0, R16
    ldi     R16, (1 << TOV0)
    sts     TIFR0, R16

	//Configuracion del prescaler
	ldi R16, (1 << CLKPCE)
	sts CLKPR, R16 // Habilitar cambio de PRESCALER
	ldi R16, 0b00000100
	sts CLKPR, R16
	ldi R16, (1<<CS02) | (1<<CS00)
	out TCCR0B, R16 // Setear prescaler 1024
	ldi R16, 22
	out TCNT0, R16
    sei                  ; Habilitar interrupciones globales
;______________________________________________________________________________


;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;								C Ó D I G O 
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________


;______________________________________________________________________________
MAIN_LOOP:
	in temp, PIND
	and temp, 0x00001000 // [Boton de estados]
	rcall ANTI_REBOTE
	breq CAMBIAR_ESTADO
;______________________________________________________________________________


;______________________________________________________________________________
CAMBIAR_ESTADO:
	inc estados
	cpi estados, 6
	brne PRIMER_ESTADO
	clr estados
	rjmp MAIN_LOOP

PRIMER_ESTADO:
	cpi estados, 0
	brne SEGUNDO_ESTADO
	clr temp
	ldi temp, 0b00000001 //Estado 1
	out portB, temp
	rcall CONFIRMACION
	clr temp
	ldi display, 0b00011000
	out portb, display
	clr display
	ldi display, 0b11000000
	out portc, display
	clr display
	rjmp RELOJ //[ESTADO 1]

SEGUNDO_ESTADO:
	cpi estados, 1
	brne TERCER_ESTADO
	clr temp
	ldi temp, 0b00000010 //Estado 2
	out portB, temp
	rcall CONFIRMACION
	clr temp
	rjmp AJUSTE_RELOJ //[ESTADO 2]

TERCER_ESTADO:
	cpi estados, 2
	brne CUARTO_ESTADO 
	clr temp
	ldi temp, 0b00000011 //Estado 3
	out portB, temp
	rcall CONFIRMACION
	clr temp
	rjmp FECHA //[ESTADO 3]

CUARTO_ESTADO:
	cpi estados, 3
	brne QUINTO_ESTADOS
	clr temp
	ldi temp, 0b00000100
	out portB, temp
	rcall CONFIRMACION
	clr temp
	rjmp CONFIGURACION_FECHA

QUINTO_ESTADO:
	cpi estados, 4
	brne FALLO
	clr temp
	ldi temp, 0b00000101
	rcall CONFIRMACION
	clr temp
	rjmp ALARMA
;______________________________________________________________________________

;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				            P R I M E R - E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________

;______________________________________________________________________________
RELOJ:
	brvc RELOJ // Overflow a 1 segundo
	clv
	cpi estados, 0
	brne CAMBIAR_ESTADOS 
	inc contador
	cpi contador, 60
	brne CONTEO
	inc un_min
	cpi un_min, 10
	brne LCD_UN_MIN // Si no es 10, cambia el valor en el display
	// Pasaron 10 minutos
	ldi un_min, 0
	rcall LCD_UN_MIN // Actualiza el valor a 0 en el display
	inc dec_min
	cpi dec_min, 6
	brne LCD_DEC_MIN // Si no es 6, cambia el valor en el display
	// Pasaron 60 minutos
	ldi dec_min, 0
	rcall LCD_DEC_MIN // Actualiza el valor a 0 en el display
	inc un_hora
	inc horas_totales
	cpi un_hora, 10
	brne LCD_UN_HORA // Si no es 10, cambia el valor en el display
	// Pasaron 10 horas
	ldi un_hora, 0
	rcall LCD_UN_HORA // Actualiza el valor a 1 en el display
	inc dec_hora
	cpi horas_totales, 24
	brne LCD_DEC_HORA
	// Pasaron 24 horas
	ldi un_min, 0 
	rcall LCD_UN_MIN // Actualiza el valor a 0 en el display
	ldi dec_min, 0
	rcall LCD_DEC_MIN // Actualiza el valor a 0 en el display
	ldi un_hora, 0
	rcall LCD_UN_HORA
	ldi dec_hora, 0
	rcall LCD_DEC_HORA
	rjmp CONTEO
;______________________________________
;######################################
;______________________________________
LCD_UN_MIN:
	ldi display, 0b00001000
	out portb, display
	clr display
	out portc, un_min
	ldi display, 0b00011000
	out portb, display
	clr display
	ret
;______________________________________
;######################################
;______________________________________
LCD_DEC_MIN:
	ldi display, 0b00010000
	out portb, display
	clr display
	out portc, dec_min
	ldi display, 0b00011000
	out portb, display
	clr display
	ret
;______________________________________
;######################################
;______________________________________
LCD_UN_HORA:
	ldi display, 0b01000000
	out portd, display
	clr display
	out portc, un_hora
	ldi display, 0b11000000
	out portd, display
	clr display
	ret
;______________________________________
;######################################
;______________________________________
LCD_DEC_HORA:
	ldi display, 0b10000000
	out portd, display
	clr display
	out portc, dec_hora
	ldi display, 0b11000000
	out portd, display
	clr display
	out
;______________________________________________________________________________

;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				          S E G U N D O - E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________

;______________________________________________________________________________
AJUSTE_RELOJ:
    ldi r16, 0x05
    out TCCR0, r16
    ldi r16, 0x01
    out TIMSK, r16
    ldi r16, 123   ; Precarga inicial para ajustar los 500 ms
    out TCNT0, r16
;______________________________________
;######################################
;______________________________________

	


;______________________________________________________________________________
; Retardo en milisegundos (entrada en temp)
ANTI_REBOTE:
    push r17
    push r18
DELAY_outER:
    ldi r18, 199
DELAY_INNER:
    dec r18
    brne DELAY_INNER
    dec temp
    brne DELAY_outER
    pop r18
    pop r17
    ret
;______________________________________________________________________________

CONFIRMACION:
	in temp, PIND
	rcall ANTI_REBOTE
	cpi temp, 0b00000100 //boton de confirmación
	breq ret
	clr temp
	in temp, PIND
	cpi temp, 0b00001000
	breq CAMBIAR_ESTADO
	rjmp CONFIRMACION
	

FALLO:
	clr temp
	ldi temp, 0x00110000
	out portB, temp