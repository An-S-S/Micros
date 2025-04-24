/*
 * led_pwm.h
 *
 * Created: 24/04/2025 01:42:21
 *  Author: André
 */ 


#ifndef LED_PWM_H
#define LED_PWM_H

#include <stdint.h>

void LEDPWM_Init();
void LEDPWM_SetDuty(uint8_t duty);

#endif