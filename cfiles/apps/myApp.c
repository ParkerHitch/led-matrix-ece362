#include "application.h"
#include <stdint.h>

void initMyApp();
void deinitMyApp();
void renderMyApp();

Application myApp = {
    .initFn = &initMyApp,
    .renderFn = &renderMyApp,
    .deinitFn = &deinitMyApp,

    .name = "Fun App",
    .authorfirst = "Homeboy",
    .authorlast = "pcock",

    .targetFPS = 30,
    .needsAccel = false,
    .needsJoystick = false
};

// Application* myApp = &myAppReal;


void initMyApp() {
    return;
}
void deinitMyApp() {
    return;
}
void renderMyApp() {
    // set_pixel(buffer, 0,0,0, RED);
    // set_pixel(buffer, 1,1,1, BLUE);
    return;
}

