/*
 * PWM.c
 *
 * Created: 11/04/2025 11:43:17
 *  Author: André
 */ 
#include "pwm_servo.h"

void PWM_Init() {
	DDRB |= (1 << DDB1) | (1 << DDB2); // PB1 y PB2 como salidas

	// Modo Fast PWM con ICR1 como TOP (Modo 14)
	TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11); // No inversor en ambos canales
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11) | (1 << CS10); // Prescaler 64

	ICR1 = 4999; // Periodo de 20ms (50Hz)
	OCR1A = 250; // Pulso inicial de 1ms (Servo 1)
	OCR1B = 250; // Pulso inicial de 1ms (Servo 2)
}

void PWM_SetDutyCycleA(uint16_t duty) {
	OCR1A = duty;
}

void PWM_SetDutyCycleB(uint16_t duty) {
	OCR1B = duty;
}