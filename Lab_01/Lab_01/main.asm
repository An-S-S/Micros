;*********************************************************
; Universidad del Valle de Guatemala
; IE2023: Programaci?n de Microcontroladores
; Laboratorio 01: Sumador
;
; Author : Eduardo André Sosa Sajquim
; Proyecto: Sumador
; Hardware: ATMega328P
; Creado: 06/febrero/2025
; Modificado: 12/02/2025
; Descripción: Contador que tendrá la capacidad de aumentar
;			   o disminuir con pushbuttons.
;*********************************************************
.include "m328pdef.inc"

.cseg
.org 0x0000

; Configuración de la pila
    LDI   R16, LOW(RAMEND)
    OUT   SPL, R16
    LDI   R16, HIGH(RAMEND)
    OUT   SPH, R16
    RJMP  INICIO

INICIO:

    LDI   R16, 0xC0       ; 1100 0000: PD6 y PD7 en salida
    OUT   DDRD, R16
    LDI   R16, 0x3F       ; 0011 1111: Habilitar pull-up en PD0-PD5
    OUT   PORTD, R16

    ; Configurar PORTB como salida (todos los pines)
    LDI   R16, 0xFF
    OUT   DDRB, R16

	LDI R16, 0xFF
	OUT DDRC, R16

    ; Inicializar contadores:
    LDI   R17, 0x00       ; Contador 1 (4 bits: 0–15)
    LDI   R20, 0x00       ; Contador 2 (4 bits: 0–15)
    RCALL ACTUALIZAR      ; Mostrar estado inicial en PORTB y PORTD
    RJMP  MAIN

MAIN:
    ; --- Botón en PD2 (mask 0x04) para INCREMENTAR contador 1 ---
	RCALL SUMA
    IN    R25, PIND
    ANDI  R25, 0x04       ; Extrae el bit PD2
    CPI   R25, 0x00       ; ¿Está en 0? (botón presionado)
    BRNE  CHECK_PD3      ; Si no, salta al siguiente botón
    LDI   R24, 0x04       ; Guarda la máscara para debounce
    RCALL DEBOUNCE
    RCALL INCREMENTAR1
    RCALL WAIT_RELEASE

CHECK_PD3:
    ; --- Botón en PD3 (mask 0x08) para DECREMENTAR contador 1 ---
    IN    R25, PIND
    ANDI  R25, 0x08
    CPI   R25, 0x00
    BRNE  CHECK_PD4
    LDI   R24, 0x08
    RCALL DEBOUNCE
    RCALL DECREMENTAR1
    RCALL WAIT_RELEASE

CHECK_PD4:
    ; --- Botón en PD4 (mask 0x10) para INCREMENTAR contador 2 ---
    IN    R25, PIND
    ANDI  R25, 0x10
    CPI   R25, 0x00
    BRNE  CHECK_PD5
    LDI   R24, 0x10
    RCALL DEBOUNCE
    RCALL INCREMENTAR2
    RCALL WAIT_RELEASE

CHECK_PD5:
    ; --- Botón en PD5 (mask 0x20) para DECREMENTAR contador 2 ---
    IN    R25, PIND
    ANDI  R25, 0x20
    CPI   R25, 0x00
    BRNE  MAIN          ; Si no está presionado, vuelve al inicio
    LDI   R24, 0x20
    RCALL DEBOUNCE
    RCALL DECREMENTAR2
    RCALL WAIT_RELEASE
    RJMP  MAIN

INCREMENTAR1:
    INC   R17           ; Incrementa contador 1
    ANDI  R17, 0x0F     ; Limita a 4 bits
    RCALL ACTUALIZAR
    RET

DECREMENTAR1:
    DEC   R17           ; Decrementa contador 1
    ANDI  R17, 0x0F
    RCALL ACTUALIZAR
    RET

INCREMENTAR2:
    INC   R20           ; Incrementa contador 2
    ANDI  R20, 0x0F
    RCALL ACTUALIZAR
    RET

DECREMENTAR2:
    DEC   R20           ; Decrementa contador 2
    ANDI  R20, 0x0F
    RCALL ACTUALIZAR
    RET

SUMA:
    MOV   R22, R17       ; R22 = contador 1
    ADD   R22, R20       ; R22 = R17 + R20   (resultado 0..30)
    CPI   R22, 0x10      ; Compara con 16 (0x10)
    BRLO  NO_CARRY       ; Si resultado < 16, no hay carry
    SUBI  R22, 0x10      ; Si hay carry, R22 = R22 - 16 (resultado de 4 bits)
    LDI   R23, 1         ; Flag de carry = 1
    RJMP  SUMA_DONE
NO_CARRY:
    LDI   R23, 0         ; Flag de carry = 0
SUMA_DONE:
    MOV   R24, R22
    ANDI  R24, 0x0F      ; Solo se conservan los 4 bits menos significativos
    IN    R25, PORTC
    ANDI  R25, 0xF0      ; Limpia los 4 bits inferiores (donde se mostrará el resultado)
    OR    R25, R24       ; Combina el resultado en los bits 0-3
    TST   R23
    BRNE  SET_CARRY
    ANDI  R25, 0x6F      ; Si no hay carry, se fuerza que PC7 esté apagado (bit7=0)
    RJMP  OUTPUT_SUM
SET_CARRY:
    ORI   R25, 0x60      ; Activa PC7 (bit7=1)
OUTPUT_SUM:
    OUT   PORTC, R25     ; Actualiza PORTC
    RET

ACTUALIZAR:
    ; Actualizar PORTB:
    MOV   R22, R17       ; R22 <- contador 1
    ANDI  R22, 0x0F
    MOV   R23, R20       ; R23 <- contador 2
    ANDI  R23, 0x03      ; Extrae bits 0 y 1 de R20
    ; Desplazar esos bits 4 posiciones a la izquierda:
    LSL   R23
    LSL   R23
    LSL   R23
    LSL   R23           ; Ahora (R20 & 0x03) << 4
    OR    R22, R23      ; Combina: PB0-PB3 = contador1, PB4-PB5 = parte baja de contador2
    ANDI  R22, 0x3F     ; Asegura que solo se afecten PB0-PB5 (0x3F = 0011 1111)
    OUT   PORTB, R22

    ; Actualizar PORTD (PD6-PD7 con los bits altos de contador2):
    MOV   R23, R20      ; R23 <- contador2
    LSR   R23           ; Desplaza 1 vez
    LSR   R23           ; Desplaza 2 veces; ahora R23[1:0] = bits originalmente en posiciones 3-2
    ANDI  R23, 0x03     ; Limpiar a 2 bits
    ; Desplazar esos 2 bits a la posición PD6-PD7 (6 desplazamientos):
    LSL   R23
    LSL   R23
    LSL   R23
    LSL   R23
    LSL   R23
    LSL   R23           ; Ahora R23 = ((R20 >> 2) & 0x03) << 6
    IN    R24, PORTD    ; Leer estado actual de PORTD
    ANDI  R24, 0x3F     ; Limpiar PD6-PD7 (mantener PD0-PD5 intactos)
    OR    R24, R23
    OUT   PORTD, R24
    RET

DEBOUNCE:
    RCALL DELAY_DEBOUNCE  ; Se llama a un retardo más largo
    IN    R25, PIND
    AND   R25, R24
    CPI   R25, 0x00       ; Se verifica que el botón siga en 0 (presionado)
    BRNE  DEBOUNCE       ; Si no, se repite el retardo
    RET

WAIT_RELEASE:
WAIT_REL_LOOP:
    IN    R25, PIND
    AND   R25, R24
    CP   R25, R24       ; Cuando (PIND & máscara) = máscara, el botón está liberado
    BRNE  WAIT_REL_LOOP
    RET

DELAY_DEBOUNCE:
    LDI   R26, 0x06      ; 6 iteraciones (puedes ajustar este valor)
DEB_DELAY_LOOP:
    RCALL DELAY          ; Retardo general (puedes ajustar DELAY si es muy largo)
    DEC   R26
    BRNE  DEB_DELAY_LOOP
    RET

DELAY:
    LDI   R18, 0x20
DELAY_LOOP1:
    LDI   R19, 0xFF
DELAY_LOOP2:
    DEC   R19
    BRNE  DELAY_LOOP2
    DEC   R18
    BRNE  DELAY_LOOP1
    RET
