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
#define Bit_Un PORTB3
#define Bit_Dc PORTB2
const uint8_t Digito_Displ[16]= {
	0x3F, 0x06, 0x5B, 0x4F,
	0x66, 0x6D, 0x7D, 0x07,
	0x7F, 0x6F, 0x77, 0x7C,
	0x39, 0x5E, 0x79, 0x71
	
};
uint8_t Contador = 0;
uint16_t Valor_ADC = 0;
/****************************************/
// Function prototypes
/****************************************/
void setup();
uint8_t boton_presionado(uint8_t pin);
void initADC();
void mux();
/****************************************/
// Main Function
/****************************************/

int main()
{
	setup();
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

		
		mux();
	}

while (Valor_ADC > Contador)
{
	PORTB = (1 << PINB5);
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
	DDRC	= 0xFF;
	PORTC	= 0x00; // Inicio Apagado
	// Configurar entradas
	DDRB   |= 0x00;
	PORTB  |= (1 << PINB0)  | (1 << PINB1);
	// Configurar pines inecesarios
	UCSR0B  = 0x00;
//-------------------------------------------
	// Configurar prescaler de sistema
	CLKPR   = (1 << CLKPCE);
	CLKPR  |= (1 << CLKPS2); // 16 -> 1MHz
//-------------------------------------------
	// Configurar ADC
	initADC();
//-------------------------------------------
	// Habilitar interrupciones globales
	sei();
}

//_______________________________________________
//												 |
//			       B O T O N					 |
//												 |
//_______________________________________________

uint8_t boton_presionado(uint8_t pin) 
{
	if (!(PINB & (1 << pin))) // Si el botón está presionado (LOW)
	{
		_delay_ms(25);                 // Espera 
		if (!(PINB & (1 << pin))) // Vuelve a verificar
		{
			return 1;
		}
	}
	return 0;
}

//_______________________________________________
//												 |
//			           A D C					 |
//												 |
//_______________________________________________

void initADC()
{
	ADMUX = 0;
	ADMUX |= (1 << REFS0) | (1 << ADLAR) | (1 << MUX2) | (1 << MUX1);

	ADCSRA = 0;
	ADCSRA |= (1 << ADPS1) | (1 << ADPS0) | (1 << ADIE) | (1 << ADEN);
	ADCSRA |= (1 << ADSC);
}

//_______________________________________________
//												 |
//			           M U X					 |
//												 |
//_______________________________________________

void mux()
{	
	uint8_t Valor_Dc = Valor_ADC/16;
	uint8_t Valor_Un = Valor_ADC%16;
	PORTB &= ~(1 << PINB3) | (1 << PINB2);
	PORTC = Digito_Displ[(Valor_Dc)];
	PORTB = 0b00000100;
	_delay_ms(5);
	
	PORTB &= ~(1 << PINB3) | (1 << PINB2);
	PORTC = Digito_Displ[(Valor_Un)];
	PORTB = 0b00001000;
	_delay_ms(5);
}

/****************************************/
// Interrupt subroutines
ISR(ADC_vect)
{
	Valor_ADC = ADCH;
	ADCSRA |= (1 << ADSC);
}