#include "application.h"
#include <stdint.h>

int32_t initMyApp();
void deinitMyApp();
void renderMyApp();

Application myAppReal = {
    .initFn = &initMyApp,
    .renderFn = &renderMyApp,
    .deinitFn = &deinitMyApp,

    .targetFPS = 30,
    .needsAccel = false,
    .needsJoystick = false
};

Application* myApp = &myAppReal;


int32_t initMyApp() {
    return 0;
}
void deinitMyApp() {
    return;
}
void renderMyApp(FrameBuffer* buffer) {
    set_pixel(buffer, 0,0,0, RED);
    set_pixel(buffer, 1,1,1, BLUE);
    return;
}

