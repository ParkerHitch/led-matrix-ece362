const microzig = @import("microzig");
const std = @import("std");
const cImport = @import("../cImport.zig");
const apps = @import("../main.zig").apps;
const deltaT = @import("./deltaTime.zig");

var prev_button_pressed = false;
var cur_button_pressed = false;
var cur_left = false;
var cur_right = false;
var cur_up = false;
var cur_down = false;
var prev_left = false;
var prev_right = false;
var prev_up = false;
var prev_down = false;

var button_memory_byte: u8 = 0;
var left_memory_byte: u8 = 0;
var right_memory_byte: u8 = 0;
var up_memory_byte: u8 = 0;
var down_memory_byte: u8 = 0;

pub const JoystickDirEnum = enum { BUTTON, LEFT, RIGHT, UP, DOWN };
pub var voltVec = [2]u32{ 0, 0 };

// seting up adc
pub fn joystick_init() void {
    cImport.init_adc(&voltVec);
}

// on-press events
pub fn button_pressed() callconv(.C) bool {
    const dummy_cur = cur_button_pressed;
    const dummy_prev = prev_button_pressed;

    if (button_memory_byte != 0xFF) {
        cur_button_pressed = false;
    }
    prev_button_pressed = cur_button_pressed;

    return (dummy_cur and !dummy_prev);
}

pub fn moved_up() callconv(.C) bool {
    const dummy_cur = cur_up;
    const dummy_prev = prev_up;

    if (up_memory_byte == 0x00) {
        cur_up = false;
    }
    prev_up = cur_up;

    return (dummy_cur and !dummy_prev);
}

pub fn moved_down() callconv(.C) bool {
    const dummy_cur = cur_down;
    const dummy_prev = prev_down;

    if (down_memory_byte == 0x00) {
        cur_down = false;
    }
    prev_down = cur_down;

    return (dummy_cur and !dummy_prev);
}

pub fn moved_right() callconv(.C) bool {
    const dummy_cur = cur_right;
    const dummy_prev = prev_right;

    if (right_memory_byte == 0x00) {
        cur_right = false;
    }
    prev_right = cur_right;

    return (dummy_cur and !dummy_prev);
}

pub fn moved_left() callconv(.C) bool {
    const dummy_cur = cur_left;
    const dummy_prev = prev_left;

    if (left_memory_byte == 0x00) {
        cur_left = false;
    }
    prev_left = cur_left;

    return (dummy_cur and !dummy_prev);
}

// memory byte handling
pub fn memory_byte_full(dir: JoystickDirEnum) bool {
    return switch (dir) {
        .BUTTON => button_memory_byte == 0xFF,
        .LEFT => left_memory_byte == 0xFF,
        .RIGHT => right_memory_byte == 0xFF,
        .UP => up_memory_byte == 0xFF,
        .DOWN => down_memory_byte == 0xFF,
    };
}

pub fn memory_byte_shift(dir: JoystickDirEnum, value: u8) void {
    switch (dir) {
        .BUTTON => button_memory_byte = (button_memory_byte << 1) + value,
        .LEFT => left_memory_byte = (left_memory_byte << 1) + value,
        .RIGHT => right_memory_byte = (right_memory_byte << 1) + value,
        .UP => up_memory_byte = (up_memory_byte << 1) + value,
        .DOWN => down_memory_byte = (down_memory_byte << 1) + value,
    }
}

pub fn update_cur_value(dir: JoystickDirEnum) void {
    switch (dir) {
        .BUTTON => cur_button_pressed = true,
        .LEFT => cur_left = true,
        .RIGHT => cur_right = true,
        .UP => cur_up = true,
        .DOWN => cur_down = true,
    }
}

pub fn cur(dir: JoystickDirEnum) bool {
    return switch (dir) {
        .BUTTON => cur_button_pressed,
        .LEFT => cur_left,
        .RIGHT => cur_right,
        .UP => cur_up,
        .DOWN => cur_down,
    };
}

// allows interupt to check position
pub fn is_in_range(dir: JoystickDirEnum) bool {
    return switch (dir) {
        .BUTTON => false,
        .LEFT => voltVec[0] < 500,
        .RIGHT => voltVec[0] > 3400,
        .UP => voltVec[1] > 3400,
        .DOWN => voltVec[1] < 500,
    };
}
