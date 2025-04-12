const cImports = @import("cImport.zig");
const matrix = @import("subsystems/matrix.zig");
const cFrameBuffer = cImports.cFrameBuffer;

pub export fn set_pixel(buff: *cFrameBuffer, x: u8, y: u8, z: u8, color: u8) void {
    matrix.FrameBuffer.set_pixel(@ptrCast(buff), @intCast(x), @intCast(y), @intCast(z), @bitCast(@as(u3, @intCast(color))));
}
