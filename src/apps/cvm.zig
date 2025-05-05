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

pub const app: Application = .{
    .renderFn = &render,

    .name = "CVM",
    .authorfirst = "Parker",
    .authorlast = "Hitchcock",
};

const shaftFloor = FpInt.fromFloat(-5);
const shaftTip = FpInt.fromFloat(5);
const shaftR = FpInt.fromFloat(2);
const shaftR2 = shaftR.mul(shaftR);
const redBallC = Vec{
    .x = FpInt.fromFloat(3.0),
    .y = FpInt.fromFloat(2.0),
    .z = shaftFloor,
};
// R squared
const redBallR2 = FpInt.fromFloat(math.pow(f32, 2.0, 2.0));
const greenBallC = Vec{
    .x = FpInt.fromFloat(-3.0),
    .y = FpInt.fromFloat(2.0),
    .z = shaftFloor,
};
const greenBallR2 = FpInt.fromFloat(math.pow(f32, 2.0, 2.0));

fn render() callconv(.C) void {
    imu.restartOrientation();

    while (true) {
        // Inputs
        if (joystick.button_pressed()) {
            break;
        }

        imu.updateOrientation();
        if (buttonA.pressed()) {
            imu.zeroOrientation();
        }
        const cubeToController = imu.getZeroedOrientation().conjugate();

        matrix.clearFrame(.{ .r = 0, .g = 0, .b = 0 });
        // var zRaw = imu.AngleFpInt{.raw = 0};
        var raw = Vec{ .x = .{ .raw = 0 }, .y = .{ .raw = 0 }, .z = .{ .raw = 0 } };
        while (raw.z.fp.integer < 8) : (raw.z = raw.z.add(1)) {
            // UartDebug.printIfDebug("z", .{}) catch {};
            raw.y = .{ .raw = 0 };
            while (raw.y.fp.integer < 8) : (raw.y = raw.y.add(1)) {
                // UartDebug.printIfDebug("y", .{}) catch {};
                raw.x = .{ .raw = 0 };
                while (raw.x.fp.integer < 8) : (raw.x = raw.x.add(1)) {
                    // Scale to coords where 0,0,0 is center of cube (located in between leds) and each led is 2 units apart
                    const cube = raw.mul(2).add(comptime .{ .x = -7, .y = -7, .z = -7 });

                    // Coordinates relative to the controller
                    const posCtrl: Vec = cubeToController.rotateVector(cube);
                    // UartDebug.printIfDebug("Mapping:\n", .{}) catch {};
                    // raw.prettyPrint(UartDebug.writer, 5) catch {};
                    // cube.prettyPrint(UartDebug.writer, 5) catch {};
                    // posCtrl.prettyPrint(UartDebug.writer, 5) catch {};

                    const toR = posCtrl.sub(redBallC).mag2();
                    // toR <= redBallR2
                    if (!toR.gt(redBallR2)) {
                        matrix.setPixel(raw.x.fp.integer, raw.y.fp.integer, raw.z.fp.integer, .{ .r = 1, .g = 0, .b = 0 });
                        continue;
                    }

                    const toG = posCtrl.sub(greenBallC).mag2();
                    // toR <= redBallR2
                    if (!toG.gt(greenBallR2)) {
                        matrix.setPixel(raw.x.fp.integer, raw.y.fp.integer, raw.z.fp.integer, .{ .r = 0, .g = 1, .b = 0 });
                        continue;
                    }

                    // If we are in the vertical bounds of the shaft
                    if (posCtrl.z.gt(shaftFloor) and shaftTip.gt(posCtrl.z)) {
                        // Calc distance to the shaft
                        const d2Shaft2 = posCtrl.x.mul(posCtrl.x).add(posCtrl.y.mul(posCtrl.y));
                        if (shaftR2.gt(d2Shaft2)) {
                            matrix.setPixel(raw.x.fp.integer, raw.y.fp.integer, raw.z.fp.integer, .{ .r = 0, .g = 0, .b = 1 });
                        }
                    }
                }
            }
        }

        matrix.render();
    }
}
