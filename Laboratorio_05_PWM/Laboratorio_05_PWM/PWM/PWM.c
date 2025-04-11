/*
 * PWM.c
 *
 * Created: 11/04/2025 11:43:17
 *  Author: André
 */ 
#include "pwm.h"

void PWM_Init() {
	DDRB |= (1 << DDB1) | (1 << DDB2);  // PB1 y PB2 como salidas
	
	// Configurar Timer1 para PWM fase correcta con ICR1 como TOP
	TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << CS11);  // Prescaler 8
	
	ICR1 = 39999;  // Periodo de 20ms (50Hz)
	
	// Valores iniciales para posición neutral (1.5ms)
	OCR1A = 2999;
	OCR1B = 2999;
}

void PWM_SetServo1(uint16_t pulseWidth) {
	OCR1A = pulseWidth;
}

void PWM_SetServo2(uint16_t pulseWidth) {
	OCR1B = pulseWidth;
}