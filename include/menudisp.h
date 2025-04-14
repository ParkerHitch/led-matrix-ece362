// #include "stm32f0xx.h"
#include "stm32f091xc.h"
#include "application.h"
#include <stdint.h>
// #include <stdio.h>
#define WHITE       0xFFFF
#define BLACK       0x0000
#define LIGHTBLUE   0X7D7C
#define LIGHTGRAY   0XEF5B
#define LGRAY       0XC618
#define GRAY        0X8430
// #define MAXAPPS 10 // read the name


// shorthand notation for 8-bit and 16-bit unsigned integers
typedef uint8_t u8;
typedef uint16_t u16;

void internal_clock();
void nano_wait(int t);
void LCD_Setup(void);
void LCD_Init(void (*reset)(int), void (*select)(int), void (*reg_select)(int));
void LCD_Clear(u16 Color);
void LCD_DrawPoint(u16 x,u16 y,u16 c);
void LCD_DrawLine(u16 x1, u16 y1, u16 x2, u16 y2, u16 c);
void LCD_DrawRectangle(u16 x1, u16 y1, u16 x2, u16 y2, u16 c);
void LCD_DrawFillRectangle(u16 x1, u16 y1, u16 x2, u16 y2, u16 c);
void LCD_DrawChar(u16 x,u16 y,u16 fc, u16 bc, char num, u8 size);
void LCD_DrawString(u16 x,u16 y, u16 fc, u16 bg, const char *p, u8 size);
void LCD_WriteReg(uint8_t, uint16_t);
void LCD_WriteRAM_Prepare(void);
void LCD_WriteData16_Prepare();
void LCD_WriteData16(u16);
void LCD_WriteData16_End();
void LCD_WR_REG(uint8_t);
void LCD_WR_DATA(uint8_t);
static void _LCD_Fill(u16, u16, u16, u16, u16);
void LCD_DrawFillRectangle(u16, u16, u16, u16, u16);
// void init_exti();
// void EXTI0_1_IRQHandler();
// void EXTI2_3_IRQHandler();
void jump_to_app(Application);
void reload_menu(char*, char**);
void shift_screen(int, char**);
void update_display();

// needed struct to change lcd
typedef struct
{
    u16 width;
    u16 height;
    u16 id;
    u8  dir;
    u16  wramcmd;
    u16  setxcmd;
    u16  setycmd;
    void (*reset)(int);
    void (*select)(int);
    void (*reg_select)(int);
} lcd_dev_t;

// important lcd info
#define LCD_W 240
#define LCD_H 320
#define SPI SPI2
