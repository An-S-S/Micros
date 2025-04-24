/*
 * adc.h
 *
 * Created: 11/04/2025 17:36:18
 *  Author: eduan
 */ 


#ifndef ADC_H
#define ADC_H

#include <stdint.h>

void ADC_Init();
void ADC_SelectChannel(uint8_t channel);
uint16_t ADC_Read();

#endif