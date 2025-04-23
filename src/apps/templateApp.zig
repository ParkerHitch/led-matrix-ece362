/// To make your own app simply copy this file and edit it as you see fit.
/// keep in mind to read all warnings and notes.
/// WARN: c headers and zig header do not have the process,
/// so read the language specific template file
const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
// const rand = std.Random; // <-- uncomment for random lib
//
// const test = rand.DefaultPrng;

// NOTE: matrix.setPixel and matrix.clearFrame are the only 2
// basic matrix pixel set functions. All future drawing abstractions
// should be placed outside the matrix.zig file, and use setPixel and or clearFrame

// NOTE: helper functions are allowed but should not be pub functions to keep file scope

// WARN: required struct header must be named app,
// .renderFn must be a pointer to your app's entry point,
// you MUST add &@import("<your file name>.zig").app to the zigApps in index.zig,
// and your file name must not be the same as any other app
pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Template Zig App",
    .authorfirst = "John",
    .authorlast = "Burns",
};

// app entry point
pub fn appMain() callconv(.C) void {
    // NOTE: for random number generator uncomment the rand include,
    // and use deltaTime.timestamp() as a seed
    // rand.DefaultPrng.init(@intCast(deltaTime.timestamp())); <-- for seeding random

    // dt struct is usded for keeping tract of time between frames
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // time keeping vairiables to limit tickRate
    const tickRate: u32 = 24; // i.e. target fps or update rate
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // collision consts
    const matrixLowerBound: i32 = 0;
    const matrixUpperBound: i32 = 7;

    // variable for keeping track the color to draw
    var drawIdx: u32 = 0;

    // yz-plane x pos and velocity
    var xVel: i32 = 1; // units per tick
    var xPos: i32 = 0;

    // TODO: replace true in while true with joystick press exit condition
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

            // collision detection & resolution
            if (xPos > matrixUpperBound) {
                xPos = matrixUpperBound;
                xVel *= -1;
            } else if (xPos < matrixLowerBound) {
                xPos = matrixLowerBound;
                xVel *= -1;
            }

            // draw to the display
            // NOTE: must start with clearing the frame and end with
            // rendering the frame else the frame before last will remain
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
