#include "stm32f0xx.h"
#include <stdint.h>

void setup_adc(void)
{

  RCC->AHBENR |= RCC_AHBENR_GPIOCEN;
  RCC->APB2ENR |= RCC_APB2ENR_ADC1EN;

  // configuring GPIOC 0 and 1 for analog mode
  GPIOC->MODER |= GPIO_MODER_MODER0;
  GPIOC->MODER |= GPIO_MODER_MODER1;

  // configuring GPIOC 2 for pull down input
  GPIOC->MODER &= ~GPIO_MODER_MODER2;
  GPIOC->PUPDR &= ~GPIO_PUPDR_PUPDR2;
  GPIOC->PUPDR |= GPIO_PUPDR_PUPDR2_1;

  // enabling HSI14 and waiting for stability
  RCC->CR2 |= RCC_CR2_HSI14ON;
  while ((RCC->CR2 & RCC_CR2_HSI14RDY) == 0)
  {
  }

  // enabling ADC and waiting for stability
  ADC1->CR |= ADC_CR_ADEN;
  while ((ADC1->ISR & ADC_ISR_ADRDY) == 0)
  {
  }

  // turning off the channels
  ADC1->CR &= ~(ADC_CR_ADSTART);

  // configuring ADC
  ADC1->CFGR1 |= ADC_CFGR1_CONT;
  ADC1->CFGR1 &= ~(ADC_CFGR1_ALIGN);
  ADC1->CFGR1 &= ~(ADC_CFGR1_RES);
  ADC1->CFGR1 &= ~(ADC_CFGR1_SCANDIR);
  ADC1->CFGR1 |= ADC_CFGR1_DMACFG;
  ADC1->CFGR1 |= ADC_CFGR1_DMAEN;

  // turning on channels 10 and 11
  ADC1->CHSELR |= (ADC_CHSELR_CHSEL10 | ADC_CHSELR_CHSEL11);
  while ((ADC1->ISR & ADC_ISR_ADRDY) == 0)
  {
  }

  // setting sampling time
  ADC1->SMPR &= ~(0b111);
  ADC1->SMPR |= 0b010;

  ADC1->CR |= ADC_CR_ADSTART;

  // DMA configuration
  RCC->AHBENR |= RCC_AHBENR_DMA1EN;
  DMA1_Channel1->CCR &= ~DMA_CCR_EN;
  DMA1_Channel1->CMAR = (u_int32_t)(&joystick);
  DMA1_Channel1->CPAR = (u_int32_t)(&(ADC1->DR));

  // setting number of data registers
  DMA1_Channel1->CNDTR = 2;

  // configuring the channel
  DMA1_Channel1->CCR &= ~(DMA_CCR_MSIZE);
  DMA1_Channel1->CCR |= DMA_CCR_MSIZE_1;
  DMA1_Channel1->CCR &= ~(DMA_CCR_PSIZE);
  DMA1_Channel1->CCR |= DMA_CCR_PSIZE_1;
  DMA1_Channel1->CCR |= DMA_CCR_MINC;
  DMA1_Channel1->CCR &= ~(DMA_CCR_PINC);
  DMA1_Channel1->CCR |= DMA_CCR_CIRC;
  DMA1_Channel1->CCR &= ~DMA_CCR_DIR;

  // turning on channel 1
  DMA1_Channel1->CCR |= DMA_CCR_EN;
}