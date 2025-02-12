#include "stm32f0xx.h"

void enable_dma(void) {
    DMA1_Channel5->CCR |= DMA_CCR_EN;
}
