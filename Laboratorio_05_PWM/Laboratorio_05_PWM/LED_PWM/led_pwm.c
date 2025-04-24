/*
 * led_pwm.c
 *
 * Created: 24/04/2025 01:41:38
 *  Author: André
 */ 
#include "led_pwm.h"
#include <avr/io.h>

void LEDPWM_Init() {
	DDRB |= (1 << DDB3); // PB3 como salida
	
	// Timer2 en modo Fast PWM, prescaler 64 (frecuencia = 16MHz / 64 / 256 ? 976.56Hz)
	TCCR2A = (1 << COM2A1) | (1 << WGM21) | (1 << WGM20); // Modo 7 (Fast PWM)
	TCCR2B = (1 << CS22); // Prescaler 64
	
	OCR2A = 0; // Inicialmente apagado
}

void LEDPWM_SetDuty(uint8_t duty) {
	OCR2A = duty; // Duty cycle de 0 a 255
}