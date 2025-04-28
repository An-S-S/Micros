/*
 * Laboratorio_06_UART.c
 *
 * Created: 25/04/2025 00:22:41
 * Author : Andr�
 * Description:
 */ 
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000 // Frecuencia del reloj (16 MHz)
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>
#define BAUD 9600
#define MYUBRR F_CPU/16/BAUD-1
// Buffer para almacenar la cadena recibida
#define BUFFER_SIZE 32
char received_buffer[BUFFER_SIZE];
uint8_t buffer_index = 0;
/****************************************/
// Function prototypes

/****************************************/
// Main Function
// Inicializaci�n UART
void UART_Init(unsigned int ubrr) {
	UBRR0H = (ubrr >> 8);
	UBRR0L = ubrr;
	UCSR0B = (1 << TXEN0) | (1 << RXEN0);
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void UART_Transmit(unsigned char data) {
	while (!(UCSR0A & (1 << UDRE0)));
	UDR0 = data;
}

unsigned char UART_Receive(void) {
	while (!(UCSR0A & (1 << RXC0)));
	return UDR0;
}

void cadena(char txt[]) {
	while (*txt != '\0') {
		UART_Transmit(*txt);
		txt++;
	}
}

// Configuraci�n ADC
void ADC_Init() {
	ADMUX = (1 << REFS0); // AVCC como referencia
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
}

uint16_t ADC_Read(uint8_t channel) {
	ADMUX = (ADMUX & 0xF0) | (channel & 0x0F);
	ADCSRA |= (1 << ADSC);
	while (ADCSRA & (1 << ADSC));
	return ADC;
}

// Env�a tabla ASCII (caracteres 32 a 126)
void Enviar_Ascii() {
	cadena("\r\nTabla ASCII:\r\n");
	for (uint8_t i = 32; i < 127; i++) {
		char buffer[16];
		snprintf(buffer, sizeof(buffer), "%3d: %c  ", i, i);
		cadena(buffer);
		if ((i - 31) % 4 == 0) cadena("\r\n"); // 4 columnas
	}
	cadena("\r\n");
}

// Muestra el men�
void Mostrar_Menu() {
	cadena("\r\n==== MENU ====\r\n");
	cadena("1. Leer Potenciometro\r\n");
	cadena("2. Enviar Ascii\r\n");
	cadena("Elija opcion: ");
}

int main(void) {
	UART_Init(MYUBRR);
	ADC_Init();
	DDRB = 0xFF;
	
	cadena("Sistema listo\r\n");
	
	while(1) {
		Mostrar_Menu();
		buffer_index = 0;
		
		// Limpiar buffer UART antes de leer
		while (UCSR0A & (1 << RXC0)) { UDR0; } // Vac�a el buffer de recepci�n
		
		// Leer comando
		while(1) {
			char received = UART_Receive();
			
			if (received == '\r' || received == '\n') {
				received_buffer[buffer_index] = '\0';
				break;
			}
			else if (buffer_index < BUFFER_SIZE - 1 && received >= ' ') { // Ignora caracteres no imprimibles
				received_buffer[buffer_index] = received;
				buffer_index++;
			}
		}
		
		// Procesar solo el primer car�cter v�lido
		char opcion = received_buffer[0];
		switch(opcion) {
			case '1': {
				uint16_t adc_valor = ADC_Read(0);
				char buffer[20];
				snprintf(buffer, sizeof(buffer), "\r\nValor ADC: %04u\r\n", adc_valor);
				cadena(buffer);
				break;
			}
			case '2':
			Enviar_Ascii();
			break;
			default:
			cadena("\r\nOpcion invalida!\r\n");
			break;
		}
		
		// Limpiar buffer recibido despu�s de procesar
		buffer_index = 0;
		received_buffer[0] = '\0';
	}
}
/****************************************/
// NON-Interrupt subroutines

/****************************************/
// Interrupt routines


