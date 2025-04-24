/*
 * Laboratorio_05_PWM.c
 *
 * Created: 11/04/2025 00:38:46
 * Author : André
 * Description: Laboratorio dónde se pondrá en uso el módulo PWM
 */ 
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000
#include "PWM\pwm_servo.h"
#include "ADC\adc.h"
#include "LED_PWM\led_pwm.h"
#include <util/delay.h>
#include <avr/io.h>
#include <math.h>
#define FILTER_SAMPLES 5
#define HYSTERESIS_THRESHOLD 2
#define ALPHA 0.2
uint16_t smoothed_adc = 0;
/****************************************/
// Function prototypes

/****************************************/
// Main Function
uint16_t applyLowPassFilter(uint16_t new_sample) {
	smoothed_adc = (uint16_t)(ALPHA * new_sample + (1 - ALPHA) * smoothed_adc);
	return smoothed_adc;
}

uint16_t readFilteredADC(uint8_t channel) {
	uint32_t sum = 0;
	for (uint8_t i = 0; i < FILTER_SAMPLES; i++) {
		ADC_SelectChannel(channel);
		sum += ADC_Read();
		_delay_us(50);
	}
	return sum / FILTER_SAMPLES;
}

uint8_t mapADCtoPWM(uint16_t adc_val) {
	return (uint8_t)(((uint32_t)adc_val * 255 + 511) / 1023); // +511 para redondear
}


int main() {
	ADC_Init();
	PWM_Init();
	LEDPWM_Init();

	uint8_t last_led_duty = 0;
	uint16_t smoothed_adc = 0;

	while(1) {
		// Lectura del potenciómetro del LED (PC3)
		uint16_t raw_adc = readFilteredADC(3);
		smoothed_adc = applyLowPassFilter(raw_adc); // Filtro pasa bajos
		
		uint8_t new_duty = mapADCtoPWM(smoothed_adc);
		
		// Histéresis para evitar fluctuaciones
		if (abs(new_duty - last_led_duty) > HYSTERESIS_THRESHOLD || new_duty == 0 || new_duty == 255) {
			LEDPWM_SetDuty(new_duty);
			last_led_duty = new_duty;
		}

		// Control de servos (sin cambios)
		ADC_SelectChannel(5);
		uint16_t adc_servo1 = ADC_Read();
		uint16_t duty_servo1 = ((uint32_t)adc_servo1 * 250) / 1023 + 250;
		PWM_SetDutyCycleA(duty_servo1);

		ADC_SelectChannel(4);
		uint16_t adc_servo2 = ADC_Read();
		uint16_t duty_servo2 = ((uint32_t)adc_servo2 * 250) / 1023 + 250;
		PWM_SetDutyCycleB(duty_servo2);

		_delay_ms(50);
	}
}
/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines

