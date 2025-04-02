/*
 * Laboratorio #4 ADC
 *
 * Created: 1/abril/2024
 * Author: Eduardo André Sosa
 * Description: Laboratorio para poner en práctica 
 *				el sistema de ADC.
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>

/****************************************/
// Function prototypes
void setup();
void initADC();
/****************************************/
// Main Function
int main(void)
{
	setup();
	while(1)
	{
		
	}
}

/****************************************/
// NON-Interrupt subroutines
void setup()
{
	cli();
	// Configurar prescaler de sistema
	CLKPR  = (1 << CLKPCE); 
	CLKPR = (1 << CLKPS2); // 16 -> 1MHz
	
	DDRD = 0xFF;
	UCSR0B = 0x00;
	
	initADC();
	
	sei();
}

void initADC()
{
	ADMUX = 0;
	ADMUX &= ~(1 << REFS1);
	ADMUX |= (1 << REFS0) | (1 << ADLAR) | (1 << MUX2) | (1 << MUX1) | (1 << MUX0);

	ADCSRA = 0;
	ADCSRA |= (1 << ADPS1) | (1 << ADPS0) | (1 << ADIE) | (1 << ADEN);
}
/****************************************/
// Interrupt routines
ISR(ADC_vect)
{
	PORTD = ADCH;
	ADCSRA |= (1 << ADSC);
}
