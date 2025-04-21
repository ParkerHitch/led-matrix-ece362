const microzig = @import("microzig");
const std = @import("std");
const cImport = @import("../cImport.zig");
const Joystick: type = @import("joystick.zig");
const apps = @import("../main.zig").apps;

extern var APP_NUM: c_int;
extern var RUNNING_APP: c_int;

pub fn screen_init() void {
    const MENU = "Select App:";

    //init_exti();
    cImport.cMenuDisp.LCD_Setup();
    // SETS UP STARTING SCREEN
    cImport.cMenuDisp.LCD_Clear(cImport.cMenuDisp.WHITE);
    cImport.cMenuDisp.LCD_DrawFillRectangle(204, 0, 240, 320, cImport.cMenuDisp.LIGHTBLUE); // menu background
    cImport.cMenuDisp.LCD_DrawString(209, 5, cImport.cMenuDisp.WHITE, cImport.cMenuDisp.LIGHTBLUE, MENU, 26); // menu text
    // loads first 7 applications
    var i: u8 = 0;
    i = 0;
    while (i < 7) {
        cImport.cMenuDisp.LCD_DrawString(173 - (28 * (i % 7)), 21, cImport.cMenuDisp.BLACK, cImport.cMenuDisp.WHITE, apps[i].name, 26);
        if (i >= (apps.len - 1)) {
            i = 7;
        }
        i += 1;
    }
    // loads arrow
    cImport.cMenuDisp.LCD_DrawFillRectangle(0, 0, 201, 21, cImport.cMenuDisp.WHITE);
    cImport.cMenuDisp.LCD_DrawChar(173, 5, cImport.cMenuDisp.BLACK, cImport.cMenuDisp.WHITE, 62, 26);
    // loads scroll bar
    cImport.cMenuDisp.LCD_DrawFillRectangle(0, 310, 203, 320, cImport.cMenuDisp.GRAY);
    cImport.cMenuDisp.LCD_DrawFillRectangle(174, 310, 203, 320, cImport.cMenuDisp.LIGHTGRAY);
}

pub fn move_up() void {
    APP_NUM -= 1;
    if (APP_NUM < 0) {
        APP_NUM = apps.len - 1;
        cImport.cMenuDisp.shift_screen(1, @ptrCast(&apps));
    } else if (@mod(APP_NUM, 7) == 6) {
        cImport.cMenuDisp.shift_screen(1, @ptrCast(&apps));
    }
    cImport.cMenuDisp.update_display();
}

pub fn move_down() void {
    APP_NUM += 1;
    if (APP_NUM >= apps.len) {
        APP_NUM = 0;
        cImport.cMenuDisp.shift_screen(0, @ptrCast(&apps));
    } else if (@mod(APP_NUM, 7) == 0) {
        cImport.cMenuDisp.shift_screen(1, @ptrCast(&apps));
    }
    cImport.cMenuDisp.update_display();
}
