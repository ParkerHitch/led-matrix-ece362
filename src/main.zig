const std = @import("std");
const microzig = @import("microzig");
const LedMatrix = @import("subsystems/matrix.zig");
const Screen: type = @import("subsystems/screen.zig");
const Joystick: type = @import("subsystems/joystick.zig");
const cImport = @import("cImport.zig");
const Application = cImport.Application;
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;
const MenuDisp = @import("subsystems/menudisp.zig");
const zigApps = @import("apps/index.zig").zigApps;

const testApp = @import("apps/testApp.zig");

const TestSR = LedMatrix.SrChain(8, .Div4);

const ChipInit = @import("init/general.zig");

// Make sure everything gets exported
comptime {
    _ = @import("cExport.zig");
}

pub const microzig_options = .{
    .interrupts = .{
        .DMA1_Ch4_7_DMA2_Ch3_5 = microzig.interrupt.Handler{ .C = LedMatrix.IRQ_DMA1_Ch4_7_DMA2_Ch3_5 },
    },
};

extern var APP_NUM: c_int;
extern var RUNNING_APP: c_int;

pub const apps = zigApps ++ cImport.cApps;

pub fn main() void {
    ChipInit.internal_clock();
    LedMatrix.init(.Div4);
    // NOTE: TEMP
    testApp.update();

    // initializing display
    const MENU = "Select App:";
    Screen.screen_init();

    // -------------------------------------- OLD MENU CODE ------------------------------------
    // const MENU = "Select App:";

    // //init_exti();
    // cImport.cMenuDisp.LCD_Setup();
    // // SETS UP STARTING SCREEN
    // cImport.cMenuDisp.LCD_Clear(MenuDisp.WHITE);
    // cImport.cMenuDisp.LCD_DrawFillRectangle(204, 0, 240, 320, cImport.cMenuDisp.LIGHTBLUE); // menu background
    // cImport.cMenuDisp.LCD_DrawString(209, 5, cImport.cMenuDisp.WHITE, cImport.cMenuDisp.LIGHTBLUE, MENU, 26); // menu text
    // // loads first 7 applications
    // var i: u8 = 0;
    // i = 0;
    // while (i < 7) {
    //     cImport.cMenuDisp.LCD_DrawString(173 - (28 * (i % 7)), 21, cImport.cMenuDisp.BLACK, cImport.cMenuDisp.WHITE, apps[i].name, 26);
    //     if (i >= (apps.len - 1)) {
    //         i = 7;
    //     }
    //     i += 1;
    // }
    // // loads arrow
    // cImport.cMenuDisp.LCD_DrawFillRectangle(0, 0, 201, 21, cImport.cMenuDisp.WHITE);
    // cImport.cMenuDisp.LCD_DrawChar(173, 5, cImport.cMenuDisp.BLACK, cImport.cMenuDisp.WHITE, 62, 26);
    // // loads scroll bar
    // cImport.cMenuDisp.LCD_DrawFillRectangle(0, 310, 203, 320, cImport.cMenuDisp.GRAY);
    // cImport.cMenuDisp.LCD_DrawFillRectangle(174, 310, 203, 320, cImport.cMenuDisp.LIGHTGRAY);

    Joystick.joystick_init();

    while (true) {
        Joystick.joystick_update();

        if (RUNNING_APP == 1) {
            if (Joystick.button_pressed()) {
                cImport.cMenuDisp.reload_menu(MENU, @ptrCast(&apps));
                continue;
            }
        } else {
            if (Joystick.button_pressed()) {
                cImport.cMenuDisp.jump_to_app(@ptrCast(apps[@intCast(APP_NUM)]));
                continue;
            }
            if (Joystick.moved_up()) {
                Screen.move_up();
            }
            if (Joystick.moved_down()) {
                Screen.move_down();
            }
        }
        cImport.nano_wait(3333333);
    }

    // -------------------------------------- OLD MENU CODE ------------------------------------
    // var y_zeroed = true;
    // var prev_button_pressed = false;
    // var button_pressed = false;

    // var voltVec = [2]u32{ 0, 0 };
    // cImport.setup_adc(&voltVec);

    // while (true) {
    //     prev_button_pressed = button_pressed;
    //     button_pressed = (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_2) != 0;
    //     if (RUNNING_APP == 1) {
    //         if (button_pressed and !prev_button_pressed) {
    //             cImport.cMenuDisp.reload_menu(MENU, @ptrCast(&apps));
    //             continue;
    //         }
    //     } else {
    //         if (button_pressed and !prev_button_pressed) {
    //             cImport.cMenuDisp.jump_to_app(@ptrCast(apps[@intCast(APP_NUM)]));
    //             continue;
    //         }
    //         if (y_zeroed) {
    //             if (voltVec[1] > 3500) {
    //                 APP_NUM -= 1;
    //                 if (APP_NUM < 0) {
    //                     APP_NUM = apps.len - 1;
    //                     cImport.cMenuDisp.shift_screen(1, @ptrCast(&apps));
    //                 } else if (@mod(APP_NUM, 7) == 6) {
    //                     cImport.cMenuDisp.shift_screen(1, @ptrCast(&apps));
    //                 }
    //                 y_zeroed = false;
    //                 cImport.cMenuDisp.update_display();
    //             } else if (voltVec[1] < 500) {
    //                 APP_NUM += 1;
    //                 if (APP_NUM >= apps.len) {
    //                     APP_NUM = 0;
    //                     cImport.cMenuDisp.shift_screen(0, @ptrCast(&apps));
    //                 } else if (@mod(APP_NUM, 7) == 0) {
    //                     cImport.cMenuDisp.shift_screen(1, @ptrCast(&apps));
    //                 }
    //                 y_zeroed = false;
    //                 cImport.cMenuDisp.update_display();
    //             }
    //         } else {
    //             if (voltVec[1] < 2400 and voltVec[1] > 1600) {
    //                 y_zeroed = true;
    //             }
    //         }
    //     }
    //     cImport.nano_wait(3333333);
    // }
}

pub fn snek(frame: LedMatrix.Frame, red: u1, green: u1, blue: u1) void {
    var x: u3 = 0;
    var y: u3 = 0;
    var z: u3 = 0;

    while (z < 8) {
        while (y < 8) {
            while (x < 8) {
                frame.set_pixel(x, y, z, .{ .r = red, .g = green, .b = blue });
                x += 1;
            }
            y += 1;
            x = 0;
        }
        z += 1;
        y = 0;
    }
}
