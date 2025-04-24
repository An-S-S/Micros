/*
 * PWM.h
 *
 * Created: 11/04/2025 11:42:47
 *  Author: André
 */ 


#ifndef PWM_SERVO_H
#define PWM_SERVO_H

#include <avr/io.h>
#include <stdint.h>

void PWM_Init();
void PWM_SetDutyCycleA(uint16_t duty);  // Para OC1A (PB1)
void PWM_SetDutyCycleB(uint16_t duty);  // Para OC1B (PB2)

#endif