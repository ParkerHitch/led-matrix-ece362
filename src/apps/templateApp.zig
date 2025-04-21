const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");

// NOTE: matrix.setPixel and matrix.clearFrame are the only 2
// basic matrix pixel set functions. All future drawing abstractions
// should be placed outside the matrix.zig file.

// WARN: required struct header must be named app,
// .renderFn must be a pointer to your app's entry point,
// and you must add &@import("<your file name>.zig").app to the zigApps in index.zig
pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Template Zig App",
    .authorfirst = "John",
    .authorlast = "Burns",
};

const matrixLowerBound: i32 = 0;
const matrixUpperBound: i32 = 7;

// app entry point
pub fn appMain() callconv(.C) void {
    // dt struct is usded for keeping tract of time between frames
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // time keeping vairiable to limit tickRate
    const tickRate: u32 = 24; // i.e. target fps
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // variable for keeping track the color to draw
    var drawIdx: u32 = 0;
    var xVel: i32 = 1;
    var xPos: i32 = 0;

    while (true) {
        // NOTE: There are other ways to use dt for keeping track of render time.
        // This method will lock your update logic to the framerate of the display,
        // and limit the framefrate to a max value determined by tickRate
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0;

            // put your app logic here
            drawIdx = if (drawIdx >= 6) 0 else drawIdx + 1;

            // movment update
            xPos += xVel;

            // collision detection
            if (xPos > 7) {
                xPos = 7;
                xVel *= -1;
            } else if (xPos < 0) {
                xPos = 0;
                xVel *= -1;
            }

            // draw to the display last
            // must start with clearing the frame else frame before last will remain
            matrix.clearFrame(draw.Color(.BLACK));

            for (0..8) |y| {
                for (0..8) |z| {
                    matrix.setPixel(xPos, @intCast(y), @intCast(z), draw.Color(@enumFromInt(drawIdx)));
                }
            }

            matrix.render();
        }
    }
}
