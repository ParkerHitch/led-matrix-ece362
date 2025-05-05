const std = @import("std");
const cImports = @import("cImport.zig");
const matrix = @import("subsystems/matrix.zig");
const deltaTime = @import("subsystems/deltaTime.zig");
const joystick = @import("subsystems/joystick.zig");
const button_a = @import("subsystems/button_a.zig");
const button_b = @import("subsystems/button_b.zig");
const cFrameBuffer = cImports.cFrameBuffer;

pub export fn setPixel(x: i32, y: i32, z: i32, color: u16) void {
    matrix.setPixel(@intCast(x), @intCast(y), @intCast(z), @bitCast(@as(u3, @intCast(color))));
}

pub export fn clearFrame(color: u16) void {
    matrix.clearFrame(@bitCast(@as(u3, @intCast(color))));
}

comptime {
    @export(matrix.render, .{ .name = "matrixRender", .linkage = .strong });
    @export(deltaTime.timestamp, .{ .name = "dtTimestamp", .linkage = .strong });
    @export(joystick.button_pressed, .{ .name = "joystickPressed", .linkage = .strong });
    @export(joystick.moved_right, .{ .name = "joystickMovedRight", .linkage = .strong });
    @export(joystick.moved_left, .{ .name = "joystickMovedLeft", .linkage = .strong });
    @export(joystick.moved_up, .{ .name = "joystickMovedUp", .linkage = .strong });
    @export(joystick.moved_down, .{ .name = "joystickMovedDown", .linkage = .strong });
}
