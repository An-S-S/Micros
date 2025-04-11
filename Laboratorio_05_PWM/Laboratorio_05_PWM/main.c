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
#include <avr/io.h>
#include <util/delay.h>
#include "PWM\PWM.h"
/****************************************/
// Function prototypes
void ADC_Init();
uint16_t ADC_Read(uint8_t channel);
/****************************************/
// Main Function
int main() {
	PWM_Init();
	ADC_Init();
	
	// Configurar Timer2 para LED en PB3
	DDRB |= (1 << DDB3);
	TCCR2A = (1 << COM2A1) | (1 << WGM21) | (1 << WGM20);
	TCCR2B = (1 << CS22);
	
	while(1) {
		uint16_t pot1 = ADC_Read(3);  // PC3
		uint16_t pot2 = ADC_Read(4);  // PC4
		uint16_t pot3 = ADC_Read(5);  // PC5
		
		// Mapear valores a rangos de PWM
		uint16_t servo1 = 1999 + (pot1 * 2000L) / 1023;
		uint16_t servo2 = 1999 + (pot2 * 2000L) / 1023;
		uint8_t led = (pot3 * 255L) / 1023;
		
		// Actualizar PWM
		PWM_SetServo1(servo1);
		PWM_SetServo2(servo2);
		OCR2A = led;
		
		_delay_ms(20);
	}
}

/****************************************/
// NON-Interrupt subroutines
void ADC_Init() {
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
	ADMUX = (1 << REFS0);
}

uint16_t ADC_Read(uint8_t channel) {
	ADMUX = (1 << REFS0) | (channel & 0x07);
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADC;
}


/****************************************/
// Interrupt routines
