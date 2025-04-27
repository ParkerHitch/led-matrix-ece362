const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const joystick = @import("../subsystems/joystick.zig");

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Tesseract",
    .authorfirst = "John",
    .authorlast = "Burns",
};

fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();
    const tickRate: u32 = 1; // i.e. target fps
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    var drawIdx: u32 = 0;

    var appRunning: bool = true;

    while (appRunning) {
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0.0;

            joystick.joystick_update();
            appRunning = !joystick.button_pressed();

            drawIdx = if (drawIdx >= 7) 0 else drawIdx + 1;

            // draw to the display
            // must start with clearing the frame
            matrix.clearFrame(draw.Color(@enumFromInt(drawIdx)));

            for (0..3) |i| {
                const frameLoc: i32 = 1 + @as(i32, @intCast(i));
                const innerFrame: i32 = 6 - 2 * @as(i32, @intCast(i));
                const loc: i32 = @as(i32, @intCast(i));

                draw.box(frameLoc, frameLoc, loc, innerFrame, innerFrame, 1, draw.Color(.BLACK));
                draw.box(loc, frameLoc, frameLoc, 1, innerFrame, innerFrame, draw.Color(.BLACK));
                draw.box(frameLoc, loc, frameLoc, innerFrame, 1, innerFrame, draw.Color(.BLACK));
                draw.box(frameLoc, frameLoc, 7 - loc, innerFrame, innerFrame, 1, draw.Color(.BLACK));
                draw.box(7 - loc, frameLoc, frameLoc, 1, innerFrame, innerFrame, draw.Color(.BLACK));
                draw.box(frameLoc, 7 - loc, frameLoc, innerFrame, 1, innerFrame, draw.Color(.BLACK));
            }

            matrix.render();
        }
    }
}
