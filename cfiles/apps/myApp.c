#include "application.h"
#include <stdint.h>

void appMain();

Application myApp = {
    .renderFn = &appMain,

    .name = "Template C App",
    .authorfirst = "John",
    .authorlast = "Burns",
};


void appMain() {
    // set_pixel(buffer, 0,0,0, RED);
    // set_pixel(buffer, 1,1,1, BLUE);
    return;
}

