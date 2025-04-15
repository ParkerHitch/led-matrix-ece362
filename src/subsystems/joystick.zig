const microzig = @import("microzig");
const std = @import("std");
const cImport = @import("../cImport.zig");
const apps = @import("../main.zig").apps;

var y_zeroed = true;
var prev_y_zeroed: bool = true;
var prev_button_pressed = false;
var cur_button_pressed = false;

var voltVec = [2]u32{ 0, 0 };

pub fn joystick_init() void {
    cImport.setup_adc(&voltVec);
}

pub fn joystick_update() void {
    prev_button_pressed = cur_button_pressed;
    cur_button_pressed = (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_2) != 0;
    prev_y_zeroed = y_zeroed;
    y_zeroed = (voltVec[1] > 1600 and voltVec[1] < 2400);
}

pub fn button_pressed() bool {
    return (cur_button_pressed and !prev_button_pressed);
}

pub fn moved_up() bool {
    if (prev_y_zeroed and voltVec[1] > 3500) {
        y_zeroed = false;
        return true;
    }
    return false;
}

pub fn moved_down() bool {
    if (prev_y_zeroed and voltVec[1] < 500) {
        y_zeroed = false;
        return true;
    }
    return false;
}
