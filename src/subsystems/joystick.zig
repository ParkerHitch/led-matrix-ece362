const microzig = @import("microzig");
const std = @import("std");
const cImport = @import("../cImport.zig");
const apps = @import("../main.zig").apps;
const deltaT = @import("./deltaTime.zig");

var y_zeroed = true;
var prev_y_zeroed: bool = true;
var x_zeroed = true;
var prev_x_zeroed = true;
var prev_button_pressed = false;
var cur_button_pressed = false;
var dtx: deltaT.DeltaTime = .{};
var dty: deltaT.DeltaTime = .{};
var x_time_held: u32 = 0;
var y_time_held: u32 = 0;

var voltVec = [2]u32{ 0, 0 };

pub fn joystick_init() void {
    cImport.setup_adc(&voltVec);
    dtx.start();
    dty.start();
}

pub fn joystick_update() void {
    prev_button_pressed = cur_button_pressed;
    cur_button_pressed = (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_2) != 0;
    prev_y_zeroed = y_zeroed;
    y_zeroed = (voltVec[1] > 1600 and voltVec[1] < 2400);
    prev_x_zeroed = x_zeroed;
    x_zeroed = (voltVec[0] > 1600 and voltVec[0] < 2400);

    if (!x_zeroed) {
        x_time_held += dtx.milli();
        if (x_time_held > 500) {
            x_zeroed = true;
            x_time_held = 0;
        }
    } else {
        x_time_held = 0;
    }

    if (!y_zeroed) {
        y_time_held += dty.milli();
        if (y_time_held > 500) {
            y_zeroed = true;
            y_time_held = 0;
        }
    } else {
        y_time_held = 0;
    }
}

pub fn button_pressed() bool {
    return (cur_button_pressed and !prev_button_pressed);
}

pub fn moved_up() bool {
    if (prev_y_zeroed and voltVec[1] > 3500) {
        y_zeroed = false;
        dty.start();
        return true;
    }
    return false;
}

pub fn moved_down() bool {
    if (prev_y_zeroed and voltVec[1] < 500) {
        y_zeroed = false;
        dty.start();
        return true;
    }
    return false;
}

pub fn moved_right() bool {
    if (prev_x_zeroed and voltVec[0] > 3500) {
        x_zeroed = false;
        dtx.start();
        return true;
    }
    return false;
}

pub fn moved_left() bool {
    if (prev_x_zeroed and voltVec[0] < 500) {
        x_zeroed = false;
        dtx.start();
        return true;
    }
    return false;
}
