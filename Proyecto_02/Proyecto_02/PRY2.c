/*
 * CFile1.c
 *
 * Created: 22/05/2025 23:17:19
 *  Author: Enter
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include "PRY2.h"


void salidas(void) {
	//SALIDAS
	//SERVOS
	DDRB |=		(1 << DDB1) | (1 << DDB2);
	DDRD |=		(1 << DDD5) | (1 << DDD3);
	//LEDS
	DDRB |=		(1 << DDB0) | (1 << DDB3) | (1 << DDB4) | (1 << DDB5);
	DDRD |=		(1 << DDD6);
	
	//Entradas
	DDRD &= ~(1<<DDD2);
	DDRD &= ~(1<<DDD4);
	DDRD &= ~(1<<DDD7);
	PORTD |= (1 << PORTD2) | (1<<PORTD4) | (1<<PORTD7);
	PCICR |=		(1<<PCIE2);
	PCMSK2 |= (1<<PCINT18) | (1<<PCINT20) | (1<<PCINT23);
	sei();
}
void confi_timer2(){
	//CONFIGURACION TIMER2
	TCCR2A = (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);					// Fast PWM, OC0B no invertido
	TCCR2B = (1 << WGM22) | (1 << CS22) | (1 << CS21) | (1 << CS20);						// Prescaler 1024
	OCR2A  = 156;
}
void confi_timer1(){
	//CONFIGURACION TIMER1
	TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS12) | (1 << CS10);		// Prescaler 1024
	ICR1 = 156;
}
void confi_timer0(){
	//CONFIGURACION TIMER0
	CLKPR  = (1<<CLKPCE);
	CLKPR  = (1<<CLKPS0);													// 8MHz
	TCCR0A = (1 << COM0B1) | (1 << WGM01) | (1 << WGM00);					// Fast PWM, OC0B no invertido
	TCCR0B = (1 << WGM02) | (1 << CS02) | (1 << CS00);						// Prescaler 1024
	OCR0A  = 156;															// 20ms
	
	
}
void iniciar_adc(){
	cli();

	ADMUX |= (1<<REFS0);													// Voltaje de referencia 5V

	ADMUX |= (1<<MUX0) | (1<<MUX1);										// Selecciona el canal 3

	ADCSRA = (1 << ADEN)  |												// Habilitar ADC
	(1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0) |				// Prescaler 128 (125 kHz)
	(1 << ADIE);												// Habilitar interrupción del ADC

	sei();
}

void iniciar_USART(unsigned int ubrr) {
	UBRR0H = (ubrr >> 8);
	UBRR0L = ubrr;

	UCSR0B |= (1 << TXEN0) | (1 << RXEN0) | (1 << RXCIE0) ; // Habilitar transmisión

	UCSR0C |= (1 << UCSZ01) | (1 << UCSZ00);
}


void iniciar_conversion(){
	ADCSRA |= (1 << ADSC);
}

void servo1(uint16_t ancho1) {
	OCR1A = ancho1;
}
void servo2(uint16_t ancho2) {
	OCR1B = ancho2;
}
void servo3(uint16_t ancho3) {
	OCR0B = ancho3;
}
void servo4(uint16_t ancho4) {
	OCR2B = ancho4;
}

void enviar(char data) {
	while (!(UCSR0A & (1 << UDRE0)));
	UDR0 = data;

}

void cadena(char *caracteres) {
	while (*caracteres != '\0'){
		enviar(*caracteres);
		caracteres++;
	}

}