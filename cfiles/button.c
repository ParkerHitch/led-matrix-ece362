#include "stm32f0xx.h"
#include "stm32f091xc.h"
#include <stdint.h>

void init_button() {
	RCC -> APB2ENR |= RCC_APB2ENR_SYSCFGCOMPEN;
	RCC -> AHBENR |= RCC_AHBENR_GPIOCEN;
	GPIOC -> MODER &= ~GPIO_MODER_MODER3;
    GPIOC->PUPDR &= ~GPIO_PUPDR_PUPDR3;
    GPIOC->PUPDR |= GPIO_PUPDR_PUPDR3_1;
}