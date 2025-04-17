#include "application.h"
#include <stdint.h>
#include <stdlib.h>

void initFireworksApp();
void deinitFireworksApp();
void renderFireworksApp();

uint8_t X_START;
uint8_t Y_START;
int STATE = 0;
uint8_t RANDCOLOR = 0;
FrameBuffer fireworkFrame;

Application FireworksApp = {
    .initFn = &initFireworksApp,
    .renderFn = &renderFireworksApp,
    .deinitFn = &deinitFireworksApp,

    .name = "Fireworks",
    .authorfirst = "Richard",
    .authorlast = "Ye",

    .targetFPS = 10,
    .needsAccel = false,
    .needsJoystick = false,
    .needsButton = false
};

void initFireworksApp() {
    return;
}
void deinitFireworksApp() {
    return;
}
void renderFireworksApp() {
    switch (STATE)
    {
        case 0:
            // START
            X_START = rand() % (6 - 3 + 1) + 3;
            Y_START = rand() % (6 - 3 + 1) + 3;
            RANDCOLOR = rand() % 8;
            set_pixel(&fireworkFrame, X_START,Y_START,0, RANDCOLOR);
            break;
        case 1:
            set_pixel(&fireworkFrame, X_START,Y_START,1, RANDCOLOR);
            break;
        case 2:
            set_pixel(&fireworkFrame, X_START,Y_START,2, RANDCOLOR);
            break;
        case 3:
            set_pixel(&fireworkFrame, X_START,Y_START,3, RANDCOLOR);
            break;
        case 4:
            set_pixel(&fireworkFrame, X_START,Y_START,4, RANDCOLOR);
            break;
        case 5:
            set_pixel(&fireworkFrame, X_START,Y_START,5, RANDCOLOR);
            break;
        case 6:
            // SPREAD 1
            // spread out in same layer
            set_pixel(&fireworkFrame, X_START,Y_START-1,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START+1,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-1,Y_START,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+1,Y_START,5, RANDCOLOR);
            // dunno if diagonals look good here
            //top diags
            set_pixel(&fireworkFrame, X_START+1,Y_START+1,6, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-1,Y_START+1,6, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+1,Y_START-1,6, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-1,Y_START-1,6, RANDCOLOR);
            // bot diags
            set_pixel(&fireworkFrame, X_START+1,Y_START+1,4, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-1,Y_START+1,4, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+1,Y_START-1,4, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-1,Y_START-1,4, RANDCOLOR);
            // diagonals end
            set_pixel(&fireworkFrame, X_START,Y_START,4, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START,6, RANDCOLOR);
            break;
        case 7:
            // SPREAD 2
            set_pixel(&fireworkFrame, X_START,Y_START-2,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START+2,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START,5, RANDCOLOR);
            // dunno if diagonals look good here
            //top diags
            set_pixel(&fireworkFrame, X_START+2,Y_START+2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START+2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START-2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START-2,7, RANDCOLOR);
            // bot diags
            set_pixel(&fireworkFrame, X_START+2,Y_START+2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START+2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START-2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START-2,3, RANDCOLOR);
            // diagonals end
            set_pixel(&fireworkFrame, X_START,Y_START,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START,7, RANDCOLOR);
            break;
        case 8:
            // SPREAD 2 LINGERS
            set_pixel(&fireworkFrame, X_START,Y_START-2,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START+2,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START,5, RANDCOLOR);
            // dunno if diagonals look good here
            //top diags
            set_pixel(&fireworkFrame, X_START+2,Y_START+2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START+2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START-2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START-2,7, RANDCOLOR);
            // bot diags
            set_pixel(&fireworkFrame, X_START+2,Y_START+2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START+2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START-2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START-2,3, RANDCOLOR);
            // diagonals end
            set_pixel(&fireworkFrame, X_START,Y_START,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START,7, RANDCOLOR);
            break;
        case 9:
            // SPREAD 2 LINGERS AGAIN
            set_pixel(&fireworkFrame, X_START,Y_START-2,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START+2,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START,5, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START,5, RANDCOLOR);
            // dunno if diagonals look good here
            //top diags
            set_pixel(&fireworkFrame, X_START+2,Y_START+2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START+2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START-2,7, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START-2,7, RANDCOLOR);
            // bot diags
            set_pixel(&fireworkFrame, X_START+2,Y_START+2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START+2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START+2,Y_START-2,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START-2,Y_START-2,3, RANDCOLOR);
            // diagonals end
            set_pixel(&fireworkFrame, X_START,Y_START,3, RANDCOLOR);
            set_pixel(&fireworkFrame, X_START,Y_START,7, RANDCOLOR);
            break;
    }

    // Change state dependingly
    if (STATE != 9)
    {
        STATE++;
    }
    else
    {
        STATE = 0;
    }
    // set_pixel(FrameBuffer* frame, uint8_t x, uint8_t y, uint8_t z, uint8_t color);
    return;
}

