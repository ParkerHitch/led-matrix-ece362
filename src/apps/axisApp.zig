const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");

pub const app: Application = .{
    .renderFn = &render,

    .name = "TestZigApp",
    .authorfirst = "John",
    .authorlast = "Burns",
};

pub fn render() callconv(.C) void {
    while (true) {
        matrix.clearFrame(.{ .r = 0, .g = 0, .b = 0 });

        for (1..8) |x| {
            matrix.setPixel(@intCast(x), 0, 0, .{ .r = 1, .g = 0, .b = 0 });
        }
        for (1..8) |y| {
            matrix.setPixel(0, @intCast(y), 0, .{ .r = 0, .g = 1, .b = 0 });
        }
        for (1..8) |z| {
            matrix.setPixel(0, 0, @intCast(z), .{ .r = 0, .g = 0, .b = 1 });
        }
        matrix.setPixel(0, 0, 0, .{ .r = 1, .g = 1, .b = 1 });

        matrix.render();
    }
}
