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
    DeltaTime dt = (DeltaTime){ .startTime = 0, .currTime = 0 };
    dtStart(&dt);
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

    while (true) {
        dtSinceUpdate += dtMilli(&dt);
        if (dtSinceUpdate >= miliPerUpdate) {
            colorIdx = colorIdx >= 7 ? 0 : colorIdx + 1;
            dtSinceUpdate = 0;
        }

        clearFrame(colors[colorIdx]);

        matrixRender();
    }
}
