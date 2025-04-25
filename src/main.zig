const std = @import("std");
const microzig = @import("microzig");
const LedMatrix = @import("subsystems/matrix.zig");
const Screen: type = @import("subsystems/screen.zig");
const Joystick: type = @import("subsystems/joystick.zig");
const deltaTime = @import("subsystems/deltaTime.zig");
const Button_A: type = @import("subsystems/button_a.zig");
const Button_B = @import("subsystems/button_b.zig");
const Debounce = @import("init/debounce.zig");
const Draw = @import("subsystems/draw.zig");
const cImport = @import("cImport.zig");
const Application = cImport.Application;
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;
const UartDebug = @import("util/uartDebug.zig");
const zigApps = @import("apps/index.zig").zigApps;
const buildMode = @import("builtin").mode;
const ChipInit = @import("init/general.zig");

// Make sure everything gets exported
comptime {
    _ = @import("cExport.zig");
    _ = @import("init/debounce.zig");
}

pub const microzig_options = .{
    .interrupts = .{
        .DMA1_Ch4_7_DMA2_Ch3_5 = microzig.interrupt.Handler{ .C = LedMatrix.IRQ_DMA1_Ch4_7_DMA2_Ch3_5 },
        .TIM14 = microzig.interrupt.Handler{ .C = Debounce.TIM14_IRQHandler },
    },
};

extern var APP_NUM: c_int;
extern var RUNNING_APP: c_int;

pub const apps = zigApps ++ cImport.cApps;

pub fn main() void {
    ChipInit.internal_clock();
    LedMatrix.init(.Div4);
    deltaTime.init();

    if (buildMode == .Debug) {
        UartDebug.init();
    }

    // NOTE: TEMP
    // const tempAppIdx = 6;
    // const appMain = apps[tempAppIdx].renderFn.?;
    // appMain();

    // initializing display
    const MENU = "Select App:";
    Screen.screen_init();
    Joystick.joystick_init();
    cImport.init_button_a();
    cImport.init_button_b();
    cImport.init_debounce();

    UartDebug.printIfDebug("All subsystems initialized!\n", .{}) catch {};

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
                const appMain = apps[@intCast(APP_NUM)].renderFn.?;
                appMain();
                cImport.cMenuDisp.reload_menu(MENU, @ptrCast(&apps));
                LedMatrix.clearFrame(Draw.Color(.BLACK));
                LedMatrix.render();
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
}
