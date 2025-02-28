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

.include "m328pdef.inc"  ; Definiciones del ATmega328P
; Definiciones
.equ LCD_RS = 4
.equ LCD_EN = 5
.equ LCD_D4 = 0
.equ LCD_D5 = 1
.equ LCD_D6 = 2
.equ LCD_D7 = 3
;___________________

;___________________
.def temp = r16
.def horas = r17         
.def minutos = r18       
.def segundos = r19      
;___________________


;___________________
.dseg
hora_buffer: .byte 9     ; Buffer para "HH:MM:SS" + terminador
;___________________


;___________________
; Segmento de código
.cseg
.org 0x0000
    rjmp RESET           ; Vector de reset

RESET:
    ; Configurar pila
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp

    ; Configurar pines como salida (D0-D5)
    ldi temp, 0x3F       ; 00111111 (D0-D5 como salidas)
    out DDRD, temp

    ; Inicializar LCD
    rcall LCD_INIT

    ; Inicializar contadores
    clr horas
    clr minutos
    clr segundos

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
    sei                  ; Habilitar interrupciones globales

MAIN_LOOP:
    rcall ACTUALIZAR_HORA
    rcall LCD_MOSTRAR
    rjmp MAIN_LOOP

; Interrupción del Timer1 (cada segundo)
.org OVF1addr
    push temp
    in temp, SREG
    push temp

    ; Reiniciar Timer1
    ldi temp, high(62500)
    sts TCNT1H, temp
    ldi temp, low(62500)
    sts TCNT1L, temp

    ; Incrementar segundos
    inc segundos
    cpi segundos, 60
    brne FIN_INT
    clr segundos
    inc minutos
    cpi minutos, 60
    brne FIN_INT
    clr minutos
    inc horas
    cpi horas, 24
    brne FIN_INT
    clr horas

FIN_INT:
    pop temp
    out SREG, temp
    pop temp
    reti

; Inicializar LCD en modo 4 bits
LCD_INIT:
    ldi temp, 100        ; Retardo inicial
    rcall DELAY_MS
    ldi temp, 0x03       ; Iniciar en modo 8 bits
    rcall LCD_CMD_4BIT
    ldi temp, 5
    rcall DELAY_MS
    ldi temp, 0x02       ; Cambiar a modo 4 bits
    rcall LCD_CMD_4BIT
    ldi temp, 0x28       ; 4 bits, 2 líneas, 5x8
    rcall LCD_COMMAND
    ldi temp, 0x0C       ; Display on, cursor off
    rcall LCD_COMMAND
    ldi temp, 0x01       ; Limpiar pantalla
    rcall LCD_COMMAND
    ldi temp, 2
    rcall DELAY_MS
    ret

; Enviar comando al LCD
LCD_COMMAND:
    push temp
    mov r20, temp
    swap r20            ; Enviar nibble alto
    andi r20, 0x0F
    out PORTD, r20
    sbi PORTD, LCD_EN
    cbi PORTD, LCD_EN
    mov r20, temp       ; Enviar nibble bajo
    andi r20, 0x0F
    out PORTD, r20
    sbi PORTD, LCD_EN
    cbi PORTD, LCD_EN
    ldi temp, 1
    rcall DELAY_MS
    pop temp
    ret

LCD_CMD_4BIT:
    push temp
    andi temp, 0x0F
    out PORTD, temp
    sbi PORTD, LCD_EN
    cbi PORTD, LCD_EN
    pop temp
    ret

; Enviar carácter al LCD
LCD_CHAR:
    push temp
    mov r20, temp
    swap r20            ; Nibble alto
    andi r20, 0x0F
    sbi PORTD, LCD_RS
    out PORTD, r20
    sbi PORTD, LCD_EN
    cbi PORTD, LCD_EN
    mov r20, temp       ; Nibble bajo
    andi r20, 0x0F
    out PORTD, r20
    sbi PORTD, LCD_EN
    cbi PORTD, LCD_EN
    cbi PORTD, LCD_RS
    ldi temp, 1
    rcall DELAY_MS
    pop temp
    ret

; Actualizar buffer de hora
ACTUALIZAR_HORA:
    push temp
    ldi r30, low(hora_buffer)  ; Puntero al buffer
    ldi r31, high(hora_buffer)

    mov temp, horas
    rcall BIN2ASCII
    st Z+, r20          ; Decenas horas
    st Z+, temp         ; Unidades horas
    ldi temp, ':'
    st Z+, temp

    mov temp, minutos
    rcall BIN2ASCII
    st Z+, r20          ; Decenas minutos
    st Z+, temp         ; Unidades minutos
    ldi temp, ':'
    st Z+, temp

    mov temp, segundos
    rcall BIN2ASCII
    st Z+, r20          ; Decenas segundos
    st Z+, temp         ; Unidades segundos
    ldi temp, 0
    st Z, temp          ; Fin de cadena
    pop temp
    ret

; Convertir binario a ASCII
BIN2ASCII:
    push r21
    ldi r21, 10
    clr r20
DIV_LOOP:
    cp temp, r21
    brlt FIN_DIV
    sub temp, r21
    inc r20
    rjmp DIV_LOOP
FIN_DIV:
    ldi r21, '0'
    add r20, r21        ; Decenas a ASCII
    add temp, r21       ; Unidades a ASCII
    pop r21
    ret

; Mostrar buffer en LCD
LCD_MOSTRAR:
    push temp
    ldi temp, 0x01      ; Limpiar pantalla
    rcall LCD_COMMAND
    ldi r30, low(hora_buffer)
    ldi r31, high(hora_buffer)
MOSTRAR_LOOP:
    ld temp, Z+
    cpi temp, 0
    breq FIN_MOSTRAR
    rcall LCD_CHAR
    rjmp MOSTRAR_LOOP
FIN_MOSTRAR:
    pop temp
    ret

; Retardo en milisegundos (entrada en temp)
DELAY_MS:
    push r17
    push r18
DELAY_OUTER:
    ldi r18, 199
DELAY_INNER:
    dec r18
    brne DELAY_INNER
    dec temp
    brne DELAY_OUTER
    pop r18
    pop r17
    ret