/*
 * PRY2.h
 *
 * Created: 22/05/2025 23:17:59
 *  Author: Enter
 */ 


#ifndef PRY2_H_
#define PRY2_H_
#include <avr/io.h>
#include <avr/eeprom.h>



void salidas();
void confi_timer0();
void confi_timer1();
void confi_timer2();
void iniciar_adc();
void iniciar_conversion();
void iniciar_USART();
void servo1(uint16_t ancho1);
void servo2(uint16_t ancho2);
void servo3(uint16_t ancho3);
void servo4(uint16_t ancho4);
void enviar(char data);
void cadena();

#endif /* PRY2_H_ */