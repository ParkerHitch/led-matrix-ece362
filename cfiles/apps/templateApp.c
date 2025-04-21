#include "application.h"
#include <stdint.h>

void appMain();

Application templateApp = {
    .renderFn = &appMain,

    .name = "Template C App",
    .authorfirst = "John",
    .authorlast = "Burns",
};


void appMain() {
    int32_t colorIdx = 0;
    uint32_t dtSinceUpdate = 0;
    const uint32_t miliPerUpdate = 1000;
    const uint16_t colors[8] = {
        RED,
        GREEN,
        BLUE,
        YELLOW,
        PURPLE,
        TIEL,
        WHITE,
        BLACK
    };

    dtStart();
    while (true) {
        dtSinceUpdate += dtMili();
        if (dtSinceUpdate >= miliPerUpdate) {
            colorIdx = colorIdx >= 7 ? 0 : colorIdx + 1;
            dtSinceUpdate = 0;
        }

        clearFrame(colors[colorIdx]);

        matrixRender();
    }
}

