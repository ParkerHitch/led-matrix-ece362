const microzig = @import("microzig");
const std = @import("std");
const cImport = @import("../cImport.zig");
const apps = @import("../main.zig").apps;
const print = @import("../util/uartDebug.zig").printIfDebug;

var prev_pressed = false;
var cur_pressed = false;
var memory_byte: u8 = 0;

pub fn pressed() bool {
    const dummy_cur = cur_pressed;
    const dummy_prev = prev_pressed;

    if (memory_byte != 0xFF) {
        cur_pressed = false;
    }
    prev_pressed = cur_pressed;

    return (dummy_cur and !dummy_prev);
}

pub fn memory_byte_full() bool {
    return (memory_byte == 0xFF);
}

pub fn memory_byte_shift(value: u32) void {
    memory_byte = (memory_byte << 1) + value;
}

pub fn update_pressed() void {
    cur_pressed = true;
}

pub fn cur() bool {
    return cur_pressed;
}
