/*
 * PWM.h
 *
 * Created: 11/04/2025 11:42:47
 *  Author: André
 */ 


#ifndef PWM_H
#define PWM_H

#include <avr/io.h>

void PWM_Init();
void PWM_SetServo1(uint16_t pulseWidth);
void PWM_SetServo2(uint16_t pulseWidth);

#endif