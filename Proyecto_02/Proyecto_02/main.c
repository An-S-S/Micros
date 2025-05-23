/*
 * Proyecto_02.c
 *
 * Created: 22/05/2025 23:15:16
 * Author : Enter
 */ 

/*
 * Proyecto_02_Motores.c
 *
 * Created: 7/05/2025 23:28:27
 * Author : André
 * Description:
 */ 
/*_________________________________________________________*/


/****************************************/
// Encabezado (Libraries)
/****************************************/
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <stdlib.h>
#include <stdio.h>
#include "PRY2.h"
/****************************************/



/****************************************/
// Function prototypes
/****************************************/
uint16_t valor_servo1 = 0;
uint16_t valor_servo2 = 0;
uint16_t valor_servo3 = 0;
uint16_t valor_servo4 = 0;
uint8_t  canal_actual = 3;
uint8_t  modo		  = 1;
uint8_t	 nuevo_valor  = 0;
char caracter;
uint16_t EEMEM eeprom_valor1;
uint16_t EEMEM eeprom_valor2;
uint16_t EEMEM eeprom_valor3;
uint16_t EEMEM eeprom_valor4;
/////////////////////////////
uint16_t EEMEM eeprom_valor1_1;
uint16_t EEMEM eeprom_valor2_1;
uint16_t EEMEM eeprom_valor3_1;
uint16_t EEMEM eeprom_valor4_1;
/////////////////////////////
uint16_t EEMEM eeprom_valor1_2;
uint16_t EEMEM eeprom_valor2_2;
uint16_t EEMEM eeprom_valor3_2;
uint16_t EEMEM eeprom_valor4_2;
/////////////////////////////
uint16_t EEMEM eeprom_valor1_3;
uint16_t EEMEM eeprom_valor2_3;
uint16_t EEMEM eeprom_valor3_3;
uint16_t EEMEM eeprom_valor4_3;
uint8_t posicion_servos = 1;

char buffer[8];
uint8_t posicion = 0;

uint16_t motor1 = 0;
uint16_t motor2 = 0;
uint16_t motor3 = 0;
uint16_t motor4 = 0;


uint16_t extraer_numero(const char *msg) {
	return atoi(&msg[3]);
}
/****************************************/



/****************************************/
// Main Function
/****************************************/
int main(void)
{
	salidas();
	confi_timer0();
	confi_timer1();
	confi_timer2();
	iniciar_USART(51);
	iniciar_adc();
	iniciar_conversion();
	while (1)
	{
		if (posicion_servos == 1){
			PORTB &= ~(1<<PORTB5);
			PORTB &= ~(1<<PORTD4);
			}else if (posicion_servos == 2){
			PORTB |= (1<<PORTB5);
			PORTB &= ~(1<<PORTD4);
			}else if (posicion_servos == 3){
			PORTB &= ~(1<<PORTB5);
			PORTB |= (1<<PORTD4);
			}else if (posicion_servos == 4){
			PORTB |= (1<<PORTB5);
			PORTB |= (1<<PORTD4);
		}
		if (modo == 1){
			PORTD |= (1<<PORTD6);
			PORTB &= ~(1<<PORTB3);
			PORTB &= ~(1<<PORTB0);
			}else if (modo == 2){
			PORTD &= ~(1<<PORTD6);
			PORTB |= (1<<PORTB0);
			PORTB &= ~(1<<PORTB3);
			}else if (modo == 3){
			PORTB &= ~(1<<PORTB0);
			PORTD &= ~(1<<PORTD6);
			PORTB |= (1<<PORTB3);
		}
	}
}
/****************************************/



/****************************************/
// NON-Interrupt subroutines
/****************************************/

/****************************************/



/****************************************/
// Interrupt routines
/****************************************/
ISR(ADC_vect)
{
	if (modo == 1){
		//char mensaje[8];
		if(canal_actual == 3)
		{
			ADMUX |= (1<<MUX2);          //cambia al canal 4
			ADMUX &= ~(1<<MUX0);
			ADMUX &= ~(1<<MUX1);
			canal_actual = 4;
			valor_servo1 = ADC;
			nuevo_valor = (4 + ((valor_servo1) * 15) / 1023);
			servo1(nuevo_valor);

		}else if (canal_actual == 4)
		{
			ADMUX |= (1<<MUX2) | (1<<MUX0);           //cambia al canal 5
			ADMUX &= ~(1<<MUX1);
			canal_actual = 5;
			valor_servo2 = ADC;
			nuevo_valor = (4 + ((valor_servo2) * 15) / 1023);
			servo2(nuevo_valor);

		}else if(canal_actual == 5)
		{
			ADMUX |= (1<<MUX2) | (1<<MUX1);          //cambia al canal 6
			ADMUX &= ~(1<<MUX0);
			canal_actual = 6;
			valor_servo3 = ADC;
			nuevo_valor = (4 + ((valor_servo3) * 15) / 1023);
			servo3(nuevo_valor);

		}else if(canal_actual == 6)
		{
			ADMUX |= (1<<MUX0) | (1<<MUX1);          //cambia al canal 3
			ADMUX &= ~(1<<MUX2);
			canal_actual = 3;
			valor_servo4 = ADC;
			nuevo_valor = (4 + ((valor_servo4) * 15) / 1023);
			servo4(nuevo_valor);

		}
	}
	iniciar_conversion();

}

ISR(PCINT2_vect) {
	
	
	if (!(PIND & (1 << PIND4))) {
		modo++;
		if(modo == 4){
			modo = 1;
		}
		
		
		if (modo == 2){
			posicion_servos = 1;
			valor_servo1 = eeprom_read_word(&eeprom_valor1);
			valor_servo2 = eeprom_read_word(&eeprom_valor2);
			valor_servo3 = eeprom_read_word(&eeprom_valor3);
			valor_servo4 = eeprom_read_word(&eeprom_valor4);
			
			///////////////////////////////////
			servo1(4 + ((valor_servo1) * 15) / 1023);
			///////////////////////////////////
			servo2(4 + ((valor_servo2) * 15) / 1023);
			///////////////////////////////////
			servo3(4 + ((valor_servo3) * 15) / 1023);
			///////////////////////////////////
			servo4(4 + ((valor_servo4) * 15) / 1023);
		}
	}
	
	if (!(PIND & (1 << PIND7))){
		posicion_servos++;
		if(posicion_servos == 5){
			posicion_servos = 1;
		}

		
		if (modo == 2){
			switch(posicion_servos){
				case (1):
				valor_servo1 = eeprom_read_word(&eeprom_valor1);
				valor_servo2 = eeprom_read_word(&eeprom_valor2);
				valor_servo3 = eeprom_read_word(&eeprom_valor3);
				valor_servo4 = eeprom_read_word(&eeprom_valor4);
				break;
				case (2):
				valor_servo1 = eeprom_read_word(&eeprom_valor1_1);
				valor_servo2 = eeprom_read_word(&eeprom_valor2_1);
				valor_servo3 = eeprom_read_word(&eeprom_valor3_1);
				valor_servo4 = eeprom_read_word(&eeprom_valor4_1);
				break;
				case (3):
				valor_servo1 = eeprom_read_word(&eeprom_valor1_2);
				valor_servo2 = eeprom_read_word(&eeprom_valor2_2);
				valor_servo3 = eeprom_read_word(&eeprom_valor3_2);
				valor_servo4 = eeprom_read_word(&eeprom_valor4_2);
				break;
				case (4):
				valor_servo1 = eeprom_read_word(&eeprom_valor1_3);
				valor_servo2 = eeprom_read_word(&eeprom_valor2_3);
				valor_servo3 = eeprom_read_word(&eeprom_valor3_3);
				valor_servo4 = eeprom_read_word(&eeprom_valor4_3);
				break;
				
			}
			///////////////////////////////////
			servo1(4 + ((valor_servo1) * 15) / 1023);
			///////////////////////////////////
			servo2(4 + ((valor_servo2) * 15) / 1023);
			///////////////////////////////////
			servo3(4 + ((valor_servo3) * 15) / 1023);
			///////////////////////////////////
			servo4(4 + ((valor_servo4) * 15) / 1023);
		}
		
	}
	if (!(PIND & (1 << PIND2))) {
		if (modo == 1 ){
			//Funcion para guardar
			switch(posicion_servos){
				case (1):
				eeprom_update_word(&eeprom_valor1, valor_servo1);
				eeprom_update_word(&eeprom_valor2, valor_servo2);
				eeprom_update_word(&eeprom_valor3, valor_servo3);
				eeprom_update_word(&eeprom_valor4, valor_servo4);
				break;
				case (2):
				eeprom_update_word(&eeprom_valor1_1, valor_servo1);
				eeprom_update_word(&eeprom_valor2_1, valor_servo2);
				eeprom_update_word(&eeprom_valor3_1, valor_servo3);
				eeprom_update_word(&eeprom_valor4_1, valor_servo4);
				break;
				case (3):
				eeprom_update_word(&eeprom_valor1_2, valor_servo1);
				eeprom_update_word(&eeprom_valor2_2, valor_servo2);
				eeprom_update_word(&eeprom_valor3_2, valor_servo3);
				eeprom_update_word(&eeprom_valor4_2, valor_servo4);
				break;
				case (4):
				eeprom_update_word(&eeprom_valor1_3, valor_servo1);
				eeprom_update_word(&eeprom_valor2_3, valor_servo2);
				eeprom_update_word(&eeprom_valor3_3, valor_servo3);
				eeprom_update_word(&eeprom_valor4_3, valor_servo4);
				break;
				
			}
			
		}

		
	}
}

ISR(USART_RX_vect) {
	if(modo == 3){
		char c = UDR0;

		if (c == '#') {
			buffer[posicion] = '\0'; // Finaliza cadena
			posicion = 0;

			if (buffer[0] == 'M' && buffer[1] == '1') {
				motor1 = extraer_numero((const char *)buffer);
				servo1(motor1);
				
				} else if (buffer[0] == 'M' && buffer[1] == '2') {
				motor2 = extraer_numero((const char *)buffer);
				servo2(motor2);
				
				} else if (buffer[0] == 'M' && buffer[1] == '3') {
				motor3 = extraer_numero((const char *)buffer);
				servo3(motor3);
				
				} else if (buffer[0] == 'M' && buffer[1] == '4') {
				motor4 = extraer_numero((const char *)buffer);
				servo4(motor4);
			}
			} else {
			buffer[posicion++] = c;
		}
	}
}
/****************************************/

