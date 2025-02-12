#include "stm32f0xx.h"
#include <stdint.h>

// get this one from /include in our project. Defines PENIS 
#include "testheader.h"

void enable_dma(void) {
    DMA1_Channel5->CCR |= DMA_CCR_EN;
}

uint8_t get_peen(uint8_t ind) {
    return PENIS[ind];
}
