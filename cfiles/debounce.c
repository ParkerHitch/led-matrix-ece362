#include "stm32f0xx.h"
#include "stm32f091xc.h"
#include <stdint.h>

void init_debounce() {

    RCC->APB1ENR |= RCC_APB1ENR_TIM14EN;

    TIM14->PSC = 24000 - 1;
    TIM14->ARR = 1000 - 1;
    TIM14->DIER |= TIM_DIER_UIE;
    NVIC->ISER[0] |= (1 << TIM14_IRQn);
    TIM14->CR1 |= TIM_CR1_CEN;

}