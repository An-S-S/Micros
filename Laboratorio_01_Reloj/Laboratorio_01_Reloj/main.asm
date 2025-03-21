;*********************************************************
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Laboratorio : 
;
; Author : Eduardo André Sosa Sajquim
; Proyecto: Reloj
; Hardware: ATMega328P
; Creado: 28/febrero/2025
; Modificado:18/marzo/2025
; Descripción: Reloj con varios estados 
;*********************************************************
;______________________________________________________________________________


;______________________________________
.include "m328pdef.inc"
;______________________________________
// 5 botones: 
// L -> R 
// -> 1. Estados/Confirmar Estado
// -> 2. Aumento(Display1)/Subir de Estado
// -> 3. Disminuir(Display1)/Bajar de Estado
// -> 4. Aumento(Display2)
// -> 5. Disminución(Display2)
// 3 leds:
// -> 1. Reloj
// -> 2. Hora
// -> 3. Configuración(Parpadeante)/Alarma(Permanente)
.def temp  = r15
.def temp2 = r16
.def temp3 = r17
.def temp4 = r18
.def temp5 = r19
//_________________________________
//*********************************
//    I N I C I O  T A B L A S
//_________________________________
//*********************************
ldi xh, 0x01
ldi xl, 0x00
ldi zh, high(Valores*2)
ldi zl, low(Valores*2)

.dseg
//_________________________________
//*********************************
//         V A L O R E S 
//_________________________________
//*********************************
Segundos: .db 0x00

Unidades_Minutos: .db 0x00

Decenas_Minutos: .db 0x00

Unidades_Horas: .db 0x00

Decenas_Horas: .db 0x00

Horas_Totales: .db 0x00

Unidades_Dia: .db 0x00

Decenas_Dia: .db 0x00

Unidades_Mes: .db 0x00

Decenas_Mes: .db 0x00

Meses_Totales: .db 0x00

Estado:  .db 0x00

Display_Actual: .db 0x00

Unidad_Minuto_Alarma: .db 0x00

Decena_Minuto_Alarma: .db 0x00

Unidad_Hora_Alarma: .db 0x00

Decena_Hora_Alarma: .db 0x00

//_________________________________
//*********************************
//         T A B L A S
//_________________________________
//*********************************
Valores:
.db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

Displays:
.db 0x01, 0x02, 0x04, 0x08
//_________________________________
//*********************************
//  I N T E R R U P C I O N E S 
//_________________________________
//*********************************
.cseg
.org 0x1200
	rjmp INICIO
.org PCMSK0
	rjmp ISR_PC
.org OVF0addr
	rjmp IDENTIFICAR_ESTADO
.org OVF1addr
	rjmp RELOJ

;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;						 I N I C I A L I Z A C I Ó N
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
INICIO:
    ; Configurar pila
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

	; Desactivar puertos usart
	ldi temp, 0x00
	sts UCSR0B, temp

	; Limpiando variables
	clr temp


	//_________________________________
	//*********************************
	//      P U E R T O  D 
	//_________________________________
	//*********************************
    ; Configurar pines D como salida [Display]
	// [0111 1111] <- Displays	(PD1 - PD7) [g f e - d c b a]
    ldi temp, 0x7F
    out DDRC, temp
	clr temp


	//_________________________________
	//*********************************
	//      P U E R T O  B 
	//_________________________________
	//*********************************
	; Configurar pines B como salida [Leds y Alarma]
	// [--00 0111] <- Leds		(PB0 - PB2) 
	// [--00 0001] <- Reloj	
	// [--00 0010] <- Fecha
	// [--00 0100] <- Alarma	
	// [--00 1000] <- Buzzer	(PB3)
	// [--01 0000] <- Estados	(PB4) 
	ldi temp, 0b00001000
	out DDRB, temp
	clr temp


	//_________________________________
	//*********************************
	//      P U E R T O  C 
	//_________________________________
	//*********************************
	; Configurar pines C como entradas/salidas [Botones]
	// [0000 0001] <- Aumentar_Display1		(PC0) -> Aumenta Display 1
	// [0000 0010] <- Disminuir_Display1	(PC1) -> Disminuir Display 1
	// [0000 0100] <- Aumentar_Display2		(PC2) -> Aumenta Display 2
	// [0000 1000] <- Disminuir_Display2	(PC3) -> Disminuir Display 2
	// [1111 0000] <- Control de displays	(PC4 - PC7) -> Para el Multiplexado [Decenas_Horas Unidades_Horas Decenas_Minutos Unidades_Minutos]
	ldi temp, 0b11110000 // <- 4 salidas y 4 entradas
	out DDRD, temp
	clr temp


	//_________________________________
	//*********************************
	//          P C I N T  
	//_________________________________
	//*********************************
	; Configurando interrupción por cambio de bit en puerto
	// Descripción general: Cuando se detecte cambio en el boton, interrupe
	// Botones en PCINT3(Estados), PCINT8(Aumento1/Aumentos_Estados), PCINT9(Disminuir1/Disminuir_Estados), PCINT10(Aumento2), PCINT11(Disminuir2)
	ldi temp, (1 << PCIE0) | (1 << PCIE1) ; Habilita interrupciones en el puerto B y C
	sts PCICR, temp ; PCICR = Registro de interrupción por cambio en pin
	clr temp
	// Primero puerto B (PCINT3)
	ldi temp, (1 << PCINT3)
	sts PCMSK0, temp
	clr temp
	// Segundo puerto C (PCINT8, PCINT9, PCINT10, PCINT11)
	ldi temp, (1 << PCINT8) | (1 << PCINT9) | (1 << PCINT10) | (1 << PCINT11)
	sts PCMSK1, temp


	//_________________________________
	//*********************************
	//           T I M E R 1
	//_________________________________
	//*********************************
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


	//_________________________________
	//*********************************
	//           T I M E R 0
	//_________________________________
	//*********************************
	; Configurar Timer0 para 5ms (Multiplexado)
	ldi	temp, (1<<CS01) | (1<<CS00)
	out TCCR0B, temp				; Setear prescaler 64
	ldi temp, 6						; Valor inicial para 5ms
	out TCNT0, temp
    ldi temp, (1 << TOIE0)
    sts TIMSK0, temp				; Modo Overfloww
    ldi temp, (1 << TOV0)
    sts TIFR0, temp					; Bandera de Overflow
	sei								; Habilitar interrupciones globales
	rjmp MAIN_LOOP
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				       B U C L E   P R I N C I P A L
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
MAIN_LOOP:
	in temp, Estado
	cpi temp, 0 ; Estado 1 (Reloj)
	breq MULTIPLEX_RELOJ
	cpi temp, 1 ; Estado 2 (Ajuste de Reloj)
	breq AJUSTE_RELOJ
	cpi temp, 2 ; Estado 3 (Fecha)
	breq MULTIPLEX_FECHA
	cpi temp, 3 ; Estado 4 (Ajuste de Fecha)
	breq AJUSTE_FECHA
	cpi temp, 4 ; Estado 5 (Configurar Alarma)
	breq ALARMA 
	cpi temp, 5 ; Estado 6 (Apagar alarma)
	breq APAGAR_ALARMA
	rjmp MAIN_LOOP
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				          R E L O J / F E C H A
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
// Lógica para determinar que multiplexado se hace
IDENTICAR_ESTADO:
	in temp, Estado
	cpi temp, 0 ; Estado 1 - Reloj
	breq MULTIPLEX_RELOJ
	cpi temp, 2 ; Estado 3 - Fecha
	breq MULTIPLEX_FECHA
	reti
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;			        L O G I C A    D E   E S T A D O S
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
// Si se presiona el boton de estados el código pasa a aquí 
ISR_PC:
    ldi temp, (1<<TOIE1) ; Habilitar interrupción por overflow
    sts TIMSK1, temp
	in temp, PINC
	eor temp, (1 << PB3)
	rjmp CAMBIO_ESTADOS

CAMBIO_ESTADOS:
	in temp, PINC 
	cpi temp, 0x01 ; Boton de Aumentar estado
	breq AUMENTAR_ESTADO
	cpi temp, 0x02 ; Boton de Disminuir estado
	breq DISMINUIR_ESTADO
	rjmp MAIN_LOOP

AUMENTAR_ESTADO:
	in temp, Estado
	inc temp
	cpi temp, 6
	breq CONFIRMAR
	ldi temp, 0
	rjmp CONFIRMAR

DISMINUIR_ESTADO:
	in temp, Estado
	dec temp
	cpi temp, 255
	breq CONFIRMAR
	ldi temp, 5
	rjmp CONFIRMAR

CONFIRMAR:
	out Estado, temp
	rjmp MAIN_LOOP
;______________________________________________________________________________




;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				            P R I M E R - E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
MULTIPLEX_RELOJ_A:
	in temp, Display_Actual
	inc temp
	cpi temp, 4
	brge REINICIO_DISPLAY_RELOJ_A
	out Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_RELOJ_A

REINICIO_DISPLAY_RELOJ_A:
	ldi temp, 0 
	out Display_Actual

ACTUALIZANDO_DISPLAY_RELOJ_A:
	ldi temp, 0x00
	out PORTC, temp
	in temp, Display_Actual
	ldi ZH, high(Displays)
	ldi ZL, low(Displays)
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	in temp, Display_Actual
	cpi temp, 0 
	breq UNIDADES_1_RELOJ_A
	cpi temp, 1
	breq DECENAS_1_RELOJ_A
	cpi temp, 2
	breq UNIDADES_2_RELOJ_A
	rjmp DECEDAS_2_RELOJ_A

UNIDADES_1_RELOJ_A:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Unidades_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	reti

DECENAS_1_RELOJ_A:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Decenas_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	reti

UNIDADES_2_RELOJ_A:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Unidades_Horas
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	reti

DECEDAS_2_RELOJ_A:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Decenas_Horas
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	reti
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				          S E G U N D O - E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
// No queremos que este contanto el reloj de timer1, por lo que se debe desactivar su interrupción
AJUSTE_RELOJ:
	ldi temp, 0x00
	sts TIMSK1, temp ; Interrupciones de Timer1 desactivadas
	in temp, Unidades_Minuto
	in temp2, Decenas_Minuto
	in temp3, Unidades_Hora
	in temp4, Decenas_Hora
	in temp5, PINC
	rcall ANTIREBOTE
	cpi temp5, 0b00000001 ; Aumentar Display 1
	breq AUMENTAR_DISPLAY_1
	cpi temp5, 0b00000010 ; Disminuir Display 1
	breq DISMINUIR_DISPLAY_1
	cpi temp5, 0b00000100 ; Aumentar Display 2
	breq AUMENTAR_DISPLAY_2
	cpi temp5, 0b00001000 ; Disminuir Display 2
	breq DISMINUIR_DISPLAY_2
	rjmp MULTIPLEX_RELOJ_AJUSTE

AUMENTAR_DISPLAY_1:
	inc temp
	cpi temp, 11
	brne SALIDA_INC_AJUSTE_RELOJ_1
	ldi temp, 0
	out Unidades_Minuto, temp
	inc temp2
	cpi temp2, 11
	brne SALIDA_INC_AJUSTE_RELOJ_2
	out Decenas_Minuto, temp
	in temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_RELOJ_REINICIO
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_RELOJ_3
	ldi temp, 0
	out Unidades_Horas, temp
	inc temp4
	out Decenas_Horas, temp4
	rjmp MULTIPLEX_RELOJ_AJUSTE

DISMINUIR_DISPLAY_1:
	dec temp
	cpi temp, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_1
	ldi temp, 10
	out Unidades_Minuto, temp
	dec temp2
	cpi temp2, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_2
	ldi temp, 10
	out Decenas_Minuto, temp
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_3
	ldi temp, 10
	out Unidades_Hora, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_4
	rjmp MULTIPLEX_RELOJ_AJUSTE

AUMENTAR_DISPLAY_2:
	in temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_RELOJ_REINICIO
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_RELOJ_3
	ldi temp, 0
	out Unidades_Horas, temp
	inc temp4
	out Decenas_Horas, temp4
	rjmp MULTIPLEX_RELOJ_AJUSTE

DISMINUIR_DISPLAY_2:
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_3
	ldi temp, 10
	out Unidades_Hora, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_4
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_INC_AJUSTE_RELOJ_1:
	out Unidades_Minuto, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_INC_AJUSTE_RELOJ_2:
	out Decenas_Minuto, temp2
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_INC_AJUSTE_RELOJ_3:
	out Unidades_Hora, temp3
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_AJUSTE_RELOJ_REINICIO:
	ldi temp, 0x00
	out Unidades_Hora, temp
	out Decenas_Hora, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_DEC_AJUSTE_RELOJ_1:
	out Unidades_Minuto, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_DEC_AJUSTE_RELOJ_2:
	out Decenas_Minuto, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_DEC_AJUSTE_RELOJ_3:
	out Unidades_Hora, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE

SALIDA_DEC_AJUSTE_RELOJ_4:
	out Decenas_Hora, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE

MULTIPLEX_RELOJ_AJUSTE:
	in temp, Display_Actual
	inc temp
	cpi temp, 4
	brge REINICIO_DISPLAY_RELOJ
	out Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_RELOJ

REINICIO_DISPLAY_RELOJ:
	ldi temp, 0 
	out Display_Actual

ACTUALIZANDO_DISPLAY_RELOJ:
	ldi temp, 0x00
	out PORTC, temp
	in temp, Display_Actual
	ldi ZH, high(Displays)
	ldi ZL, low(Displays)
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	in temp, Display_Actual
	cpi temp, 0 
	breq UNIDADES_1_RELOJ
	cpi temp, 1
	breq DECENAS_1_RELOJ
	cpi temp, 2
	breq UNIDADES_2_RELOJ
	rjmp DECEDAS_2_RELOJ

UNIDADES_1_RELOJ:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Unidades_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	rjmp AJUSTE_RELOJ

DECENAS_1_RELOJ:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Decenas_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	rjmp AJUSTE_RELOJ

UNIDADES_2_RELOJ:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Unidades_Horas
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	rjmp AJUSTE_RELOJ

DECEDAS_2_RELOJ:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	in temp, Decenas_Horas
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	rjmp AJUSTE_RELOJ
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				          T E R C E R - E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
MULTIPLEX_FECHA:
	in   temp, Display_Actual
	inc  temp
	cpi  temp, 4
	brge REINICIO_DISPLAY_FECHA_1
	out  Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_FECHA_1

REINICIO_DISPLAY_FECHA_1:
	ldi  temp, 0 
	out  Display_Actual

ACTUALIZANDO_DISPLAY_FECHA_1:
	ldi  temp, 0x00
	out  PORTC, temp
	in   temp, Display_Actual
	ldi  ZH, high(Displays)
	ldi  ZL, low(Displays)
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	in   temp, Display_Actual
	cpi  temp, 0 
	breq UNIDADES_1_FECHA
	cpi  temp, 1
	breq DECENAS_1_FECHA
	cpi  temp, 2
	breq UNIDADES_2_FECHA
	rjmp DECEDAS_2_FECHA

UNIDADES_1_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Unidades_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	reti

DECENAS_1_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Decenas_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	reti

UNIDADES_2_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Unidades_Mes
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	reti

DECEDAS_2_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Decenas_Mes
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	reti
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				           C U A R T O - E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
// No queremos que este contanto el Reloj de timer1, por lo que se debe desactivar su interrupción
AJUSTE_FECHA:
	ldi temp, 0x00
	sts TIMSK1, temp ; Interrupciones de Timer1 desactivadas
	in temp, Unidades_Dia
	in temp2, Decenas_Dia
	in temp3, Unidades_Mes
	in temp4, Decenas_Mes
	in temp5, PINC
	rcall ANTIREBOTE
	cpi temp5, 0b00000001 ; Aumentar Display 1
	breq AUMENTAR_DISPLAY_1_FECHA
	cpi temp5, 0b00000010 ; Disminuir Display 1
	breq DISMINUIR_DISPLAY_1_FECHA
	cpi temp5, 0b00000100 ; Aumentar Display 2
	breq AUMENTAR_DISPLAY_2_FECHA
	cpi temp5, 0b00001000 ; Disminuir Display 2
	breq DISMINUIR_DISPLAY_2_FECHA
	rjmp MULTIPLEX_FECHA_AJUSTE

AUMENTAR_DISPLAY_1_FECHA:
	inc temp
	cpi temp, 11
	brne SALIDA_INC_AJUSTE_FECHA_1
	ldi temp, 1
	out Unidades_Dia, temp
	inc temp2
	cpi temp2, 11
	brne SALIDA_INC_AJUSTE_FECHA_2
	out Decenas_Dia, temp
	in temp, Meses_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_FECHA_REINICIO
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_FECHA_3
	ldi temp, 0
	out Unidades_Mes, temp
	inc temp4
	out Decenas_Mes, temp4
	rjmp MULTIPLEX_FECHA_AJUSTE

DISMINUIR_DISPLAY_1_FECHA:
	dec temp
	cpi temp, 255
	brne SALIDA_DEC_AJUSTE_FECHA_1
	ldi temp, 10
	out Unidades_Dia, temp
	dec temp2
	cpi temp2, 255
	brne SALIDA_DEC_AJUSTE_FECHA_2
	ldi temp, 10
	out Decenas_Dia, temp
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_FECHA_3
	ldi temp, 10
	out Unidades_Mes, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_FECHA_4
	ldi temp, 0
	out Decenas_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

AUMENTAR_DISPLAY_2_FECHA:
	in temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_FECHA_REINICIO
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_FECHA_3
	ldi temp, 0
	out Unidades_Mess, temp
	inc temp4
	out Decenas_Mess, temp4
	rjmp MULTIPLEX_FECHA_AJUSTE

DISMINUIR_DISPLAY_2_FECHA:
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_FECHA_3
	ldi temp, 10
	out Unidades_Mes, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_FECHA_4
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_INC_AJUSTE_FECHA_1:
	out Unidades_Dia, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_INC_AJUSTE_FECHA_2:
	out Decenas_Dia, temp2
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_INC_AJUSTE_FECHA_3:
	out Unidades_Mes, temp3
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_AJUSTE_FECHA_REINICIO:
	ldi temp, 0x00
	out Unidades_Mes, temp
	out Decenas_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_1:
	out Unidades_Dia, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_2:
	out Decenas_Dia, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_3:
	out Unidades_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_4:
	out Decenas_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

MULTIPLEX_FECHA_AJUSTE:
	in   temp, Display_Actual
	inc  temp
	cpi  temp, 4
	brge REINICIO_DISPLAY_FECHA
	out  Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_FECHA

REINICIO_DISPLAY_FECHA:
	ldi  temp, 0 
	out  Display_Actual

ACTUALIZANDO_DISPLAY_FECHA:
	ldi  temp, 0x00
	out  PORTC, temp
	in   temp, Display_Actual
	ldi  ZH, high(Displays)
	ldi  ZL, low(Displays)
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	in   temp, Display_Actual
	cpi  temp, 0 
	breq UNIDADES_1_FECHA
	cpi  temp, 1
	breq DECENAS_1_FECHA
	cpi  temp, 2
	breq UNIDADES_2_FECHA
	rjmp DECEDAS_2_FECHA

UNIDADES_1_FECHA:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Unidades_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	rjmp AJUSTE_FECHA

DECENAS_1_FECHA:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Decenas_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	rjmp AJUSTE_FECHA

UNIDADES_2_FECHA:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Unidades_Mes
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	rjmp AJUSTE_FECHA

DECEDAS_2_FECHA:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	in   temp, Decenas_Mes
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	rjmp AJUSTE_FECHA
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				        	Q U I N T O   E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
ALARMA:
	out Unidad_Minuto_Alarma, Unidad_Minuto
	out Decena_Minuto_Alarma, Decena_Minuto
	out Unidad_Hora_Alarma  , Unidad_Hora
	out Decena_Hora_Alarma  , Decena_Hora
	rjmp ALARMA_ACTIVA

ALARMA_ACTIVA:
	ldi temp, 0b00000100
	out PORTD, temp
	; Condición 1
    in temp, Decena_Hora
    cp temp, Decena_Hora_Alarma
    brne ALARMA_ACTIVA
	; Condición 2
    in temp, Unidad_Hora
    cp temp, Unidad_Hora_Alarma
    brne ALARMA_ACTIVA
	; Condición 3
    in temp, Decena_Minuto
    cp temp, Decena_Minuto_Alarma
    brne ALARMA_ACTIVA
	; Condición 4
    in temp, Unidad_Minuto
    cp temp, Unidad_Minuto_Alarma
    brne ALARMA_ACTIVA
	; Se cumple todo y wiu wiu 
    rjmp ACTIVAR_ALARMA  

ACTIVAR_ALARMA:
    sbi PORTB, 0  ; Encender buzzer o LED en PB0
    rjmp MAIN_LOOP
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				        	   S E X T O  E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
DESACTIVAR_ALARMA:
	ldi temp, 0x00
	out PORTB, temp
	out Unidad_Minuto_Alarma, temp
	out Decena_Minuto_Alarma, temp
	out Unidad_Hora_Alarma  , temp
	out Decena_Hora_Alarma  , temp
	rjmp MAIN_LOOP
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				        L O G I C A  D E  I N C R E M E N T O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
RELOJ:
	inc Segundos ; Overflow cada 1seg, por lo tanto a los 60 oveflow hay 1 minuto
	cpi Segundos, 60 
	brne SALIDA
	// Cambio en unidad de minutos
	in temp, Unidades_Minutos
	inc temp
	cpi temp, 11
	brne SALIDA_RELOJ_1
	//Cambio en decena de minutos
	ldi temp, 0
	out Unidades_Minutos, temp
	in temp, Decenas_Minutos
	inc temp
	cpi temp, 11
	brne SALIDA_RELOJ_2
	// Cambio unidades horas
	ldi temp, 0
	out Decenas_Minutos, temp
	in temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq REINICIO_HORAS
	out Horas_Totales, temp
	in temp, Unidades_Horas
	inc temp
	cpi temp, 11
	brne SALIDA_RELOJ_3
	// Cambio decenas horas
	ldi temp, 0
	out Unidades_Horas, temp
	in temp, Decenas_Horas
	inc temp
	out Decenas_Horas
	reti

REINICIO_HORAS:
	ldi temp, 0x00
	out Unidades_Hora, temp
	out Decenas_Hora, temp
	out Horas_Totales, temp
	rjmp CONDICIONAMOS //Salta a fecha, pero tiene que haber algo que permita el cambio para el multiplexado, ademas, fecha es otro estado :p
	//Quiza el reloj (Conteo) como tal no es el estado, sino solo el multiplexado del tiempo
	//Hacer Varios multiplexados? Uno tiempo y otro fecha? 
	//Se puede, hay que verificar el estado en el que se encuentre el sistema y mandar la interrupción del timer0 ahí :p

CONDICIONAMOS:
	in   temp, Decena_Mes
	cpi  temp, 0
	breq CONDICION1
	rjmp CONTROL_FECHA

CONDICION1_A:
	in   temp, Unidades_Mes
	cpi  temp, 2
	breq FEBRERO
	rjmp CONTROL_FECHA

CONDICION2_A:
	in   temp, Decenas_Dia
	cpi  temp, 2
	breq CONDICION3_A
	rjmp CONTROL_FECHA

CONDICION3_A:
	in   temp, Unidades_Dia
	cpi  temp, 9
	breq FEBRERO
	rjmp CONTROL_FECHA

CONTROL_FECHA:
	in   temp, Unidades_Dia
	inc  temp
	cpi  temp, 11
	brne SALIDA_FECHA_1
	ldi  temp, 0x01 ; Regresar el valor de la unidad de dia a 1 
	out  Unidades_Dia, temp
	in   temp, Decenas_Dia
	inc  temp
	cpi  temp, 4
	brne SALIDA_FECHA_2
	ldi  temp, 0x00 ; Regresar el valor de las decenas de dia a 0
	out  Decenas_Dia, temp
	in   temp, Meses_Totales
	inc  temp
	cpi  temp, 12
	brne REINICIO_MES  ; Se cumple unos 12 meses y se reinicia el contador
	in   temp, Unidades_Mes
	inc  temp
	cpi  temp, 11
	brne SALIDA_FECHA_3
	ldi  temp, 0x00 ; Regresar el valor de la unidad de meses a 0 
	out  Unidades_Mes, temp
	in   temp, Decenas_Mes
	inc  temp ; Se incrementa el mes a 1 y sale

SALIDA:
	reti

FEBRERO:
	ldi temp, 0x00
	out Decenas_Dia, temp
	ldi temp, 0x01
	out Unidades_Dia, temp
	ldi temp, 0x03
	out Unidades_Mes, temp
	reti

REINICIO_MES:
	ldi temp, 0x01
	out Unidades_Mes, temp
	ldi temp, 0x00
	out Decenas_Mes, temp
	reti

SALIDA_RELOJ_1:
	out Unidades_Minuto, temp
	reti

SALIDA_RELOJ_2:
	out Decenas_Minuto, temp
	reti

SALIDA_RELOJ_3:
	out Unidades_Hora, temp
	reti

SALIDA_FECHA_1:
	out Unidades_Dia, temp
	reti

SALIDA_FECHA_2:
	out Decenas_Dia, temp
	reti

SALIDA_FECHA_3:
	out Unidades_Mes, temp
	reti
;______________________________________________________________________________



;______________________________________________________________________________
;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				                   A N T I R E B O T E
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
; Retardo en milisegundos (entrada en temp)
ANTIREBOTE:
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