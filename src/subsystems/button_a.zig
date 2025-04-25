const microzig = @import("microzig");
const std = @import("std");
const cImport = @import("../cImport.zig");
const apps = @import("../main.zig").apps;

var prev_reg_button_pressed = false;
var cur_reg_button_pressed = false;

pub fn button_update() void {
    prev_reg_button_pressed = cur_reg_button_pressed;
    cur_reg_button_pressed = (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_4) != 0;
}

pub fn button_pressed() bool {
    return (cur_reg_button_pressed and !prev_reg_button_pressed);
}
