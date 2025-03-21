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
.def temp = r16
.def temp1 = r17
.def temp2 = r18
.def temp3 = r19
.def temp4 = r20
.def temp5 = r21
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
Segundos: .byte 1
Unidades_Minutos: .byte 1
Decenas_Minutos: .byte 1
Unidades_Horas: .byte 1
Decenas_Horas: .byte 1
Horas_Totales: .byte 1
Unidades_Dia: .byte 1
Decenas_Dia: .byte 1
Unidades_Mes: .byte 1
Decenas_Mes: .byte 1
Meses_Totales: .byte 1
Estado:  .byte 1
Display_Actual: .byte 1
Unidad_Minuto_Alarma: .byte 1
Decena_Minuto_Alarma: .byte 1
Unidad_Hora_Alarma: .byte 1
Decena_Hora_Alarma: .byte 1
//_________________________________
//*********************************
//  I N T E R R U P C I O N E S 
//_________________________________
//*********************************
.cseg
.org 0x5
	rjmp INICIO
.org PCI0addr
	rjmp ISR_PC
.org OVF0addr
	rjmp IDENTIFICAR_ESTADO
.org OVF1addr
	rjmp RELOJ

//_________________________________
//*********************************
//         T A B L A S
//_________________________________
//*********************************
Valores: .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
Displays: .db 0x01, 0x02, 0x04, 0x08
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;						 I N I C I A L I Z A C I Ó N
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
INICIO:
	cli
    ; Configurar pila
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

	; Desactivar puertos usart
	ldi temp, 0x00
	sts UCSR0B, temp
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
    out DDRD, temp
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
	out DDRC, temp
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
	lds temp, Estado
	cpi temp, 0 ; Estado 1 (Reloj)
	breq MULTIPLEX_RELOJ_A
	cpi temp, 1 ; Estado 2 (Ajuste de Reloj)
	breq AJUSTE_RELOJ_ML
	cpi temp, 2 ; Estado 3 (Fecha)
	breq MULTIPLEX_FECHA_ML
	cpi temp, 3 ; Estado 4 (Ajuste de Fecha)
	breq AJUSTE_FECHA_ML
	cpi temp, 4 ; Estado 5 (Configurar Alarma)
	breq ALARMA_ML
	cpi temp, 5 ; Estado 6 (Apagar alarma)
	breq DESACTIVAR_ALARMA_ML
	rjmp MAIN_LOOP
AJUSTE_RELOJ_ML:
	rcall AJUSTE_RELOJ
MULTIPLEX_FECHA_ML:
	rcall MULTIPLEX_FECHA
AJUSTE_FECHA_ML:
	rcall AJUSTE_FECHA
ALARMA_ML:
	rcall ALARMA
DESACTIVAR_ALARMA_ML:
	rcall DESACTIVAR_ALARMA
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				          R E L O J / F E C H A
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
// Lógica para determinar que multiplexado se hace
IDENTIFICAR_ESTADO:
	lds temp, Estado
	cpi temp, 0 ; Estado 1 - Reloj
	breq MULTIPLEX_RELOJ_A
	cpi temp, 2 ; Estado 3 - Fecha
	breq MULTIPLEX_FECHA_IE
	reti
MULTIPLEX_FECHA_IE:
	rcall MULTIPLEX_FECHA
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
	clr temp
	in temp, PINC
	sbrc temp, PB3
CAMBIO_ESTADOS:
	in temp, PINC 
	cpi temp, 0x01 ; Boton de Aumentar estado
	breq AUMENTAR_ESTADO
	cpi temp, 0x02 ; Boton de Disminuir estado
	breq DISMINUIR_ESTADO
	rjmp MAIN_LOOP
AUMENTAR_ESTADO:
	lds temp, Estado
	inc temp
	cpi temp, 6
	breq CONFIRMAR
	ldi temp, 0
	rjmp CONFIRMAR
DISMINUIR_ESTADO:
	lds temp, Estado
	dec temp
	cpi temp, 255
	breq CONFIRMAR
	ldi temp, 5
	rjmp CONFIRMAR
CONFIRMAR:
	sts Estado, temp
	rjmp MAIN_LOOP
;______________________________________________________________________________




;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				            P R I M E R - E S T A D O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
MULTIPLEX_RELOJ_A:
	lds temp, Display_Actual
	inc temp
	cpi temp, 4
	brge REINICIO_DISPLAY_RELOJ_A
	sts Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_RELOJ_A

REINICIO_DISPLAY_RELOJ_A:
	ldi temp, 0 
	sts  Display_Actual, temp

ACTUALIZANDO_DISPLAY_RELOJ_A:
	ldi temp, 0x00
	out PORTC, temp
	lds temp, Display_Actual
	ldi ZH, high(Displays)
	ldi ZL, low(Displays)
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	lds temp, Display_Actual
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
	lds temp, Unidades_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	reti

DECENAS_1_RELOJ_A:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	lds temp, Decenas_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	reti

UNIDADES_2_RELOJ_A:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	lds temp, Unidades_Horas
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	reti

DECEDAS_2_RELOJ_A:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	lds temp, Decenas_Horas
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
	lds temp, Unidades_Minutos
	lds temp2, Decenas_Minutos
	lds temp3, Unidades_Horas
	lds temp4, Decenas_Horas
	in temp5, PINC
	rcall ANTIREBOTE
	cpi temp5, 0b00000001 ; Aumentar Display 1
	breq AUMENTAR_DISPLAY_1_B
	cpi temp5, 0b00000010 ; Disminuir Display 1
	breq DISMINUIR_DISPLAY_1_B
	cpi temp5, 0b00000100 ; Aumentar Display 2
	breq AUMENTAR_DISPLAY_2_B
	cpi temp5, 0b00001000 ; Disminuir Display 2
	breq DISMINUIR_DISPLAY_2_B_CL
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

DISMINUIR_DISPLAY_2_B_CL:
	rcall DISMINUIR_DISPLAY_2_B

AUMENTAR_DISPLAY_1_B:
	inc temp
	cpi temp, 11
	brne SALIDA_INC_AJUSTE_RELOJ_1_B_CL
	ldi temp, 0
	sts Unidades_Minutos, temp
	inc temp2
	cpi temp2, 11
	brne SALIDA_INC_AJUSTE_RELOJ_2_B_CL
	sts Decenas_Minutos, temp
	lds temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_RELOJ_REINICIO_B_CL
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_RELOJ_3_B
	ldi temp, 0
	sts Unidades_Horas, temp
	inc temp4
	sts Decenas_Horas, temp4
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_INC_AJUSTE_RELOJ_1_B_CL:
	rcall SALIDA_INC_AJUSTE_RELOJ_1_B

SALIDA_INC_AJUSTE_RELOJ_2_B_CL:
	rcall SALIDA_INC_AJUSTE_RELOJ_2_B

SALIDA_AJUSTE_RELOJ_REINICIO_B_CL:
	rcall SALIDA_AJUSTE_RELOJ_REINICIO_B

DISMINUIR_DISPLAY_1_B:
	dec temp
	cpi temp, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_1_B
	ldi temp, 10
	sts Unidades_Minutos, temp
	dec temp2
	cpi temp2, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_2_B
	ldi temp, 10
	sts Decenas_Minutos, temp
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_3_B
	ldi temp, 10
	sts Unidades_Horas, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_4_B
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

AUMENTAR_DISPLAY_2_B:
	lds temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_RELOJ_REINICIO_B
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_RELOJ_3_B
	ldi temp, 0
	sts Unidades_Horas, temp
	inc temp4
	sts Decenas_Horas, temp4
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

DISMINUIR_DISPLAY_2_B:
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_3_B
	ldi temp, 10
	sts Unidades_Horas, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_RELOJ_4_B
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_INC_AJUSTE_RELOJ_1_B:
	sts Unidades_Minutos, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_INC_AJUSTE_RELOJ_2_B:
	sts Decenas_Minutos, temp2
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_INC_AJUSTE_RELOJ_3_B:
	sts Unidades_Horas, temp3
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_AJUSTE_RELOJ_REINICIO_B:
	ldi temp, 0x00
	sts Unidades_Horas, temp
	sts Decenas_Horas, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_DEC_AJUSTE_RELOJ_1_B:
	sts Unidades_Minutos, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_DEC_AJUSTE_RELOJ_2_B:
	sts Decenas_Minutos, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_DEC_AJUSTE_RELOJ_3_B:
	sts Unidades_Horas, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

SALIDA_DEC_AJUSTE_RELOJ_4_B:
	sts Decenas_Horas, temp
	rjmp MULTIPLEX_RELOJ_AJUSTE_B

MULTIPLEX_RELOJ_AJUSTE_B:
	lds temp, Display_Actual
	inc temp
	cpi temp, 4
	brge REINICIO_DISPLAY_RELOJ_B
	sts Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_RELOJ_B

REINICIO_DISPLAY_RELOJ_B:
	ldi temp, 0 
	sts  Display_Actual, temp

ACTUALIZANDO_DISPLAY_RELOJ_B:
	ldi temp, 0x00
	out PORTC, temp
	lds temp, Display_Actual
	ldi ZH, high(Displays)
	ldi ZL, low(Displays)
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	lds temp, Display_Actual
	cpi temp, 0 
	breq UNIDADES_1_RELOJ_B
	cpi temp, 1
	breq DECENAS_1_RELOJ_B
	cpi temp, 2
	breq UNIDADES_2_RELOJ_B
	rjmp DECEDAS_2_RELOJ_B

UNIDADES_1_RELOJ_B:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	lds temp, Unidades_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	rjmp AJUSTE_RELOJ

DECENAS_1_RELOJ_B:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	lds temp, Decenas_Minutos
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	rjmp AJUSTE_RELOJ

UNIDADES_2_RELOJ_B:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	lds temp, Unidades_Horas
	add ZL, temp
	ld temp, Z
	out PORTD, temp
	rjmp AJUSTE_RELOJ

DECEDAS_2_RELOJ_B:
	ldi ZH, high(Valores)
	ldi ZL, low(Valores)
	lds temp, Decenas_Horas
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
	lds   temp, Display_Actual
	inc  temp
	cpi  temp, 4
	brge REINICIO_DISPLAY_FECHA_1
	sts  Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_FECHA_1

REINICIO_DISPLAY_FECHA_1:
	ldi  temp, 0 
	sts  Display_Actual, temp

ACTUALIZANDO_DISPLAY_FECHA_1:
	ldi  temp, 0x00
	out  PORTC, temp
	lds   temp, Display_Actual
	ldi  ZH, high(Displays)
	ldi  ZL, low(Displays)
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	lds   temp, Display_Actual
	cpi  temp, 0 
	breq UNIDADES_1_FECHA_1
	cpi  temp, 1
	breq DECENAS_1_FECHA_1
	cpi  temp, 2
	breq UNIDADES_2_FECHA_1
	rjmp DECEDAS_2_FECHA_1

UNIDADES_1_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	lds   temp, Unidades_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	reti

DECENAS_1_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	lds   temp, Decenas_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	reti

UNIDADES_2_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	lds   temp, Unidades_Mes
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	reti

DECEDAS_2_FECHA_1:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	lds   temp, Decenas_Mes
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
	lds temp, Unidades_Dia
	lds temp2, Decenas_Dia
	lds temp3, Unidades_Mes
	lds temp4, Decenas_Mes
	in temp5, PINC
	rcall ANTIREBOTE
	cpi temp5, 0b00000001 ; Aumentar Display 1
	breq AUMENTAR_DISPLAY_1_FECHA_CL
	cpi temp5, 0b00000010 ; Disminuir Display 1
	breq DISMINUIR_DISPLAY_1_FECHA
	cpi temp5, 0b00000100 ; Aumentar Display 2
	breq AUMENTAR_DISPLAY_2_FECHA
	cpi temp5, 0b00001000 ; Disminuir Display 2
	breq DISMINUIR_DISPLAY_2_FECHA_CL
	rjmp MULTIPLEX_FECHA_AJUSTE

AUMENTAR_DISPLAY_1_FECHA_CL:
	rcall AUMENTAR_DISPLAY_1_FECHA

DISMINUIR_DISPLAY_2_FECHA_CL:
	rcall DISMINUIR_DISPLAY_2_FECHA

AUMENTAR_DISPLAY_1_FECHA:
	inc temp
	cpi temp, 11
	brne SALIDA_INC_AJUSTE_FECHA_1_CL
	ldi temp, 1
	sts Unidades_Dia, temp
	inc temp2
	cpi temp2, 11
	brne SALIDA_INC_AJUSTE_FECHA_2_CL
	sts Decenas_Dia, temp
	lds temp, Meses_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_FECHA_REINICIO_CL
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_FECHA_3_CL
	ldi temp, 0
	sts Unidades_Mes, temp
	inc temp4
	sts Decenas_Mes, temp4
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_INC_AJUSTE_FECHA_1_CL:
	rcall SALIDA_INC_AJUSTE_FECHA_1
SALIDA_INC_AJUSTE_FECHA_2_CL:
	rcall SALIDA_INC_AJUSTE_FECHA_2
SALIDA_AJUSTE_FECHA_REINICIO_CL:
	rcall SALIDA_AJUSTE_FECHA_REINICIO
SALIDA_INC_AJUSTE_FECHA_3_CL:
	rcall SALIDA_INC_AJUSTE_FECHA_3

DISMINUIR_DISPLAY_1_FECHA:
	dec temp
	cpi temp, 255
	brne SALIDA_DEC_AJUSTE_FECHA_1
	ldi temp, 10
	sts Unidades_Dia, temp
	dec temp2
	cpi temp2, 255
	brne SALIDA_DEC_AJUSTE_FECHA_2
	ldi temp, 10
	sts Decenas_Dia, temp
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_FECHA_3
	ldi temp, 10
	sts Unidades_Mes, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_FECHA_4
	ldi temp, 0
	sts Decenas_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

AUMENTAR_DISPLAY_2_FECHA:
	lds temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq SALIDA_AJUSTE_FECHA_REINICIO
	inc temp3
	cpi temp3, 11
	brne SALIDA_INC_AJUSTE_FECHA_3
	ldi temp, 0
	sts Unidades_Mes, temp
	inc temp4
	sts Decenas_Mes, temp4
	rjmp MULTIPLEX_FECHA_AJUSTE

DISMINUIR_DISPLAY_2_FECHA:
	dec temp3
	cpi temp3, 255
	brne SALIDA_DEC_AJUSTE_FECHA_3
	ldi temp, 10
	sts Unidades_Mes, temp
	dec temp4
	cpi temp4, 255
	brne SALIDA_DEC_AJUSTE_FECHA_4
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_INC_AJUSTE_FECHA_1:
	sts Unidades_Dia, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_INC_AJUSTE_FECHA_2:
	sts Decenas_Dia, temp2
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_INC_AJUSTE_FECHA_3:
	sts Unidades_Mes, temp3
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_AJUSTE_FECHA_REINICIO:
	ldi temp, 0x00
	sts Unidades_Mes, temp
	sts Decenas_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_1:
	sts Unidades_Dia, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_2:
	sts Decenas_Dia, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_3:
	sts Unidades_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

SALIDA_DEC_AJUSTE_FECHA_4:
	sts Decenas_Mes, temp
	rjmp MULTIPLEX_FECHA_AJUSTE

MULTIPLEX_FECHA_AJUSTE:
	lds   temp, Display_Actual
	inc  temp
	cpi  temp, 4
	brge REINICIO_DISPLAY_FECHA
	sts  Display_Actual, temp
	rjmp ACTUALIZANDO_DISPLAY_FECHA

REINICIO_DISPLAY_FECHA:
	ldi  temp, 0 
	sts  Display_Actual, temp

ACTUALIZANDO_DISPLAY_FECHA:
	ldi  temp, 0x00
	out  PORTC, temp
	lds   temp, Display_Actual
	ldi  ZH, high(Displays)
	ldi  ZL, low(Displays)
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	lds   temp, Display_Actual
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
	lds   temp, Unidades_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	rjmp AJUSTE_FECHA

DECENAS_1_FECHA:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	lds   temp, Decenas_Dia
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	rjmp AJUSTE_FECHA

UNIDADES_2_FECHA:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	lds   temp, Unidades_Mes
	add  ZL, temp
	ld   temp, Z
	out  PORTD, temp
	rjmp AJUSTE_FECHA

DECEDAS_2_FECHA:
	ldi  ZH, high(Valores)
	ldi  ZL, low(Valores)
	lds   temp, Decenas_Mes
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
	lds temp, Unidades_Minutos
	sts Unidad_Minuto_Alarma, temp
	lds temp, Decenas_Minutos
	sts Decena_Minuto_Alarma, temp
	lds temp, Unidades_Horas
	sts Unidad_Hora_Alarma, temp
	lds temp, Decenas_Horas
	sts Decena_Hora_Alarma, temp
	rjmp ALARMA_ACTIVA

ALARMA_ACTIVA:
	ldi temp, 0b00000100
	out PORTD, temp
	; Condición 1
    lds temp, Decenas_Horas
	lds temp2, Decena_Hora_Alarma
    cp temp, temp2
    brne ALARMA_ACTIVA
	; Condición 2
    lds temp, Unidades_Horas
	lds temp2, Unidad_Hora_Alarma
    cp temp, temp2
    brne ALARMA_ACTIVA
	; Condición 3
    lds temp, Decenas_Minutos
	lds temp2, Decena_Minuto_Alarma
    cp temp, temp2
    brne ALARMA_ACTIVA
	; Condición 4
    lds temp, Unidades_Minutos
	lds temp2, Unidad_Minuto_Alarma
    cp temp, temp2
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
	sts Unidad_Minuto_Alarma, temp
	sts Decena_Minuto_Alarma, temp
	sts Unidad_Hora_Alarma  , temp
	sts Decena_Hora_Alarma  , temp
	rjmp MAIN_LOOP
;______________________________________________________________________________



;______________________________________________________________________________
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;				        L O G I C A  D E  I N C R E M E N T O
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
;______________________________________________________________________________
RELOJ:
	lds temp, Segundos
	inc temp ; Overflow cada 1seg, por lo tanto a los 60 oveflow hay 1 minuto
	cpi temp, 60 
	brne SALIDA_CL
	// Cambio en unidad de minutos
	lds temp, Unidades_Minutos
	inc temp
	cpi temp, 11
	brne SALIDA_RELOJ_1_CL
	//Cambio en decena de minutos
	ldi temp, 0
	sts Unidades_Minutos, temp
	lds temp, Decenas_Minutos
	inc temp
	cpi temp, 11
	brne SALIDA_RELOJ_2_CL
	// Cambio unidades horas
	ldi temp, 0
	sts Decenas_Minutos, temp
	lds temp, Horas_Totales
	inc temp
	cpi temp, 24
	breq REINICIO_HORAS
	sts Horas_Totales, temp
	lds temp, Unidades_Horas
	inc temp
	cpi temp, 11
	brne SALIDA_RELOJ_3_CL
	// Cambio decenas horas
	ldi temp, 0
	sts Unidades_Horas, temp
	lds temp, Decenas_Horas
	inc temp
	sts Decenas_Horas, temp
	reti

SALIDA_CL:
	rcall SALIDA
SALIDA_RELOJ_1_CL:
	rcall SALIDA_RELOJ_1
SALIDA_RELOJ_2_CL:
	rcall SALIDA_RELOJ_2
SALIDA_RELOJ_3_CL:
	rcall SALIDA_RELOJ_3

REINICIO_HORAS:
	ldi temp, 0x00
	sts Unidades_Horas, temp
	sts Decenas_Horas, temp
	sts Horas_Totales, temp
	rjmp CONDICIONAMOS //Salta a fecha, pero tiene que haber algo que permita el cambio para el multiplexado, ademas, fecha es otro estado :p
	//Quiza el reloj (Conteo) como tal no es el estado, sino solo el multiplexado del tiempo
	//Hacer Varios multiplexados? Uno tiempo y otro fecha? 
	//Se puede, hay que verificar el estado en el que se encuentre el sistema y mandar la interrupción del timer0 ahí :p

CONDICIONAMOS:
	lds   temp, Decenas_Mes
	cpi  temp, 0
	breq CONDICION1_A
	rjmp CONTROL_FECHA

CONDICION1_A:
	lds   temp, Unidades_Mes
	cpi  temp, 2
	breq FEBRERO
	rjmp CONTROL_FECHA

CONDICION2_A:
	lds   temp, Decenas_Dia
	cpi  temp, 2
	breq CONDICION3_A
	rjmp CONTROL_FECHA

CONDICION3_A:
	lds   temp, Unidades_Dia
	cpi  temp, 9
	breq FEBRERO
	rjmp CONTROL_FECHA

CONTROL_FECHA:
	lds   temp, Unidades_Dia
	inc  temp
	cpi  temp, 11
	brne SALIDA_FECHA_1
	ldi  temp, 0x01 ; Regresar el valor de la unidad de dia a 1 
	sts  Unidades_Dia, temp
	lds   temp, Decenas_Dia
	inc  temp
	cpi  temp, 4
	brne SALIDA_FECHA_2
	ldi  temp, 0x00 ; Regresar el valor de las decenas de dia a 0
	sts  Decenas_Dia, temp
	lds   temp, Meses_Totales
	inc  temp
	cpi  temp, 12
	brne REINICIO_MES  ; Se cumple unos 12 meses y se reinicia el contador
	lds   temp, Unidades_Mes
	inc  temp
	cpi  temp, 11
	brne SALIDA_FECHA_3
	ldi  temp, 0x00 ; Regresar el valor de la unidad de meses a 0 
	sts  Unidades_Mes, temp
	lds   temp, Decenas_Mes
	inc  temp ; Se incrementa el mes a 1 y sale

SALIDA:
	reti

FEBRERO:
	ldi temp, 0x00
	sts Decenas_Dia, temp
	ldi temp, 0x01
	sts Unidades_Dia, temp
	ldi temp, 0x03
	sts Unidades_Mes, temp
	reti

REINICIO_MES:
	ldi temp, 0x01
	sts Unidades_Mes, temp
	ldi temp, 0x00
	sts Decenas_Mes, temp
	reti

SALIDA_RELOJ_1:
	sts Unidades_Minutos, temp
	reti

SALIDA_RELOJ_2:
	sts Decenas_Minutos, temp
	reti

SALIDA_RELOJ_3:
	sts Unidades_Horas, temp
	reti

SALIDA_FECHA_1:
	sts Unidades_Dia, temp
	reti

SALIDA_FECHA_2:
	sts Decenas_Dia, temp
	reti

SALIDA_FECHA_3:
	sts Unidades_Mes, temp
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

