const std = @import("std");
const cImports = @import("cImport.zig");
const matrix = @import("subsystems/matrix.zig");
const deltaTime = @import("subsystems/deltaTime.zig");
const cFrameBuffer = cImports.cFrameBuffer;

pub export fn setPixel(x: i32, y: i32, z: i32, color: u16) void {
    matrix.setPixel(@intCast(x), @intCast(y), @intCast(z), @bitCast(@as(u3, @intCast(color))));
}
pub export fn clearFrame(color: u16) void {
    matrix.clearFrame(@bitCast(@as(u3, @intCast(color))));
}

comptime {
    @export(deltaTime.start, .{ .name = "dtStart", .linkage = .strong });
    @export(deltaTime.mili, .{ .name = "dtMili", .linkage = .strong });
    @export(deltaTime.seconds, .{ .name = "dtSeconds", .linkage = .strong });
    @export(matrix.render, .{ .name = "matrixRender", .linkage = .strong });
}
