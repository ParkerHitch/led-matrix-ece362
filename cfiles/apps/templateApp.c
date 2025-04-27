// To make your own app simply copy this file and edit it as you see fit.
// keep in mind to read all warnings and notes.
// WARN: c headers and zig header do not have the process,
// so read the language specific template file
#include "application.h"
#include <stdint.h>

// NOTE: setPixel() and clearFrame() are the only provided draw functions
// they take a uint_16 as a color parameter for the c implementation
// Until 4bit color values are implemented use the Color macros defined in application.h:
// RED, GREEN, BLUE, YELLOW, PURPLE, TIEL, WHITE, and BLACK (turns the pixel off)

// NOTE: helper functions are allowed but should be static to keep file scope

// WARN: required app header must be the same name as your file,
// so if your file is name myApp.c your Application header struct would be
// Application myApp = { ...
// your file name must not be the same as any other app
static void appMain();

Application templateApp = {
    .renderFn = &appMain,

    .name = "Template C App",
    .authorfirst = "John",
    .authorlast = "Burns",
};


// app entry point
static void appMain() {
    // time keeping variable
    DeltaTime dt = (DeltaTime){ .startTime = 0, .currTime = 0 };
    dtStart(&dt);

    // time keeping vairiables to limit tickRate5
    const uint32_t tickRate = 50; // i.e. target fps or update rate 
    const uint32_t updatePeroid = 1000 / tickRate; // 1000 ms * (period of a tick)
    uint32_t dtSinceUpdate = 0;

    const int32_t matrixUpperBound = 7;
    const int32_t matrixLowerBound = 0;

    int32_t colorIdx = 0;
    const uint16_t colors[7] = {
        RED,
        GREEN,
        BLUE,
        YELLOW,
        PURPLE,
        TEAL,
        WHITE
    };

    int32_t xPos = 0;
    int32_t xVel = 1;

    while (true) {
        dtSinceUpdate += dtMilli(&dt);
        if (dtSinceUpdate >= updatePeroid) {
            dtSinceUpdate = 0;

            // put your app logic here
            colorIdx = colorIdx >= 6 ? 0 : colorIdx + 1;

            // movment update
            xPos += xVel;

            // collision detection & resolution
            if (xPos > matrixUpperBound) {
                xPos = matrixUpperBound;
                xVel *= -1;
            } else if (xPos < matrixLowerBound) {
                xPos = matrixLowerBound;
                xVel *= -1;
            }

            // draw to the display
            // NOTE: must start with clearing the frame and end with
            // rendering the frame else the frame before last will remain
            clearFrame(BLACK);

            for (int y = 0; y <= matrixUpperBound; y++) {
                for (int z = 0; z <= matrixUpperBound; z++) {
                    setPixel(xPos, y, z, colors[colorIdx]);
                }
            }

            matrixRender();
        }
    }
}
