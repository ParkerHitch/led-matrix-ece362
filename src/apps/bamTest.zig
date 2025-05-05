const Application = @import("../cImport.zig").Application;
const std = @import("std");
const math = std.math;
const matrix = @import("../subsystems/matrix.zig");
const joystick = @import("../subsystems/joystick.zig");
const imu = @import("../subsystems/imu.zig");
const Vec = imu.AngleVec;
const FpInt = imu.AngleFpInt;
const buttonA = @import("../subsystems/button_a.zig");
const fp = @import("../util/fixedPoint.zig");
const UartDebug = @import("../util/uartDebug.zig");
const BAMint = matrix.BAM_int;

pub const app: Application = .{
    .renderFn = &render,

    .name = "BAM test",
    .authorfirst = "Parker",
    .authorlast = "Hitchcock",
};

fn render() callconv(.C) void {
    matrix.enableBAM();

    matrix.clearFrameBAM(.{ .r = 0, .g = 0, .b = 0 });

    for (1..8) |i| {
        const iu3: u3 = @intCast(i);
        matrix.setPixelBAM(iu3, 0, 0, .{ .r = 7 - (iu3 - 1), .g = 0, .b = 0 });
        matrix.setPixelBAM(0, iu3, 0, .{ .r = 0, .g = 7 - (iu3 - 1), .b = 0 });
        matrix.setPixelBAM(0, 0, iu3, .{ .r = 0, .g = 0, .b = 7 - (iu3 - 1) });
    }
    matrix.setPixelBAM(0, 0, 0, .{ .r = math.maxInt(BAMint), .g = math.maxInt(BAMint), .b = math.maxInt(BAMint) });

    matrix.renderBAM();
    while (true) {
        // get input
        if (joystick.button_pressed()) {
            break;
        }
    }

    matrix.disableBAM();
}
