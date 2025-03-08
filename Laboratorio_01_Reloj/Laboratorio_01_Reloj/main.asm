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
.def confirmar = r24 //boton para ver si se va al estado seleccionado
Tabla:
	.def 0 = 0x80 
	.def 1 = 0xC0
	.def 2 = 0xF9
	.def 3 = 0XA4
	.def 4 = 0XB0
	.def 5 = 0x99
	.def 6 = 0x92
	.def 7 = 0x82
	.def 9 = 0xF8     
;______________________________________


;______________________________________
.dseg
hora_buffer: .byte 9     ; Buffer para "HH:MM:SS" + terminador
;______________________________________


;______________________________________
.cseg
.org 0x0000
    rjmp INICIO
.org 0x0200
	rjmp CONTEO
LISTA:



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

    ; Configurar pines C como salida [Display]
    ldi temp, 0xFF
    out DDRC, temp
	clr temp

	; Configurar pines B como salida [Leds y Alarma]
	ldi temp, 0xFF
	out DDRB, temp
	clr temp
	
	; Configurar pines D como entradas [Botones]
	ldi temp, 0x00
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
	and temp, 0x00001000 [Boton de estados]
	rcall ANTI_REBOTE
	breq CAMBIAR_ESTADO
	
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
CONTEO:
	brvc CONTEO // Overflow a 1 segundo
	clv 
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
;______________________________________________________________________________


;______________________________________________________________________________
LCD_UN_MIN:
	mov temp, un_min

;______________________________________________________________________________


;______________________________________________________________________________
LCD_DEC_MIN:
;______________________________________________________________________________


;______________________________________________________________________________
LCD_UN_HORA:
;______________________________________________________________________________


;______________________________________________________________________________
LCD_DEC_HORA:
;______________________________________________________________________________



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