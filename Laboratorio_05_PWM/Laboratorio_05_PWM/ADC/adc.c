/*
 * adc.c
 *
 * Created: 11/04/2025 17:36:40
 *  Author: eduan
 */ 
#include "adc.h"
#include <avr/io.h>

void ADC_Init() {
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Habilitar ADC, prescaler 128
}

void ADC_SelectChannel(uint8_t channel) {
	ADMUX = (1 << REFS0) | (channel & 0x07); // Referencia AVcc, seleccionar canal
}

uint16_t ADC_Read() {
	ADCSRA |= (1 << ADSC); // Iniciar conversión
	while (ADCSRA & (1 << ADSC)); // Esperar
	return ADC;
}
