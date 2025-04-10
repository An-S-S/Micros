/*
 * Laboratorio #4 ADC
 *
 * Created: 1/abril/2024
 * Author: Eduardo André Sosa
 * Description: Laboratorio para poner en práctica 
 *				el sistema de ADC y contador binario.
 */
/****************************************/
// Encabezado (Libraries)
#define  F_CPU  16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
/****************************************/
// Function prototypes
/****************************************/
void setup();
uint8_t boton_presionado(uint8_t pin);
/****************************************/
// Main Function
/****************************************/

int main()
{
	setup();
	uint8_t Contador = 0; 
	while(1)
	{
		if (boton_presionado(PINB0))
		{
			Contador++;
			PORTD = Contador;
			_delay_ms(200);
		}
		
		if (boton_presionado(PINB1))
		{
			Contador--;
			PORTD = Contador;
			_delay_ms(200);
		}
	}
	
}

/****************************************/
// NON-Interrupt subroutines
/****************************************/

//_______________________________________________
//												 |
//			       S E T U P					 |
//												 |
//_______________________________________________

void setup()
{
	// Deshabilitar interrupciones globales
	cli();
//-------------------------------------------	
	// Configurar salidas 
	DDRD    = 0xFF;
	PORTD	= 0x00; // Inicio Apagado
	// Configurar entradas
	DDRB   &= ~(1 << PINB0) | (1 << PINB1);
	PORTB  |= (1 << PINB0)  | (1 << PINB1);
	// Configurar pines inecesarios
	UCSR0B  = 0x00;
//-------------------------------------------
	// Habilitar interrupciones globales
	sei();
}

//_______________________________________________
//												 |
//			       B O T O N					 |
//												 |
//_______________________________________________

uint8_t boton_presionado(uint8_t pin) {
	if (!(PINB & (1 << pin))) {        // Si el botón está presionado (LOW)
		_delay_ms(20);                 // Espera 
		if (!(PINB & (1 << pin))) {   // Vuelve a verificar
			return 1;
		}
	}
	return 0;
}

