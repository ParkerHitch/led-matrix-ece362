// const microzig = @import("microzig");
// const RCC = microzig.chip.peripherals.RCC;
// const FLASH = microzig.chip.peripherals.FLASH;

// void init_debounce_timer() {

//     RCC->APB1ENR |= RCC_APB1ENR_TIM14EN;
//     TIM14->PSC = 24000 - 1;
//     TIM14->ARR = 2 - 1;
//     TIM14->DIER |= TIM_DIER_UIE;
//     NVIC_EnableIRQ(TIM14_IRQn);
//     TIM14->CR1 |= TIM_CR1_CEN;

// }

// void TIM14_IRQHandler() {
//     TIM14-> SR &= ~TIM_SR_UIF;
// }
