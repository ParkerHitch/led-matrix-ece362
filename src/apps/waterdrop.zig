/// To make your own app simply copy this file and edit it as you see fit.
/// keep in mind to read all warnings and notes.
/// WARN: c headers and zig header do not have the process,
/// so read the language specific template file
const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const joystick = @import("../subsystems/joystick.zig");
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

    .name = "Waterdrop",
    .authorfirst = "Richard",
    .authorlast = "Ye",
};

fn matrixSetCheck(x: i32, y: i32, z: i32, color: matrix.Led) void {
    if (x >= 0 and x <= 7) {
        if (y >= 0 and y <= 7) {
            if (z >= 0 and z <= 7) {
                matrix.setPixel(x, y, z, color);
            }
        }
    }
}

// app entry point
fn appMain() callconv(.C) void {
    // NOTE: for random number generator uncomment the rand include,
    // and use deltaTime.timestamp() as a seed
    // rand.DefaultPrng.init(@intCast(deltaTime.timestamp())); <-- for seeding random
    // checking for exit condition

    // dt struct is usded for keeping tract of time between frames
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // time keeping vairiables to limit tickRate
    const tickRate: u32 = 10; // i.e. target fps or update rate
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // starting point and firework colors
    var x_start: i32 = 0;
    var y_start: i32 = 0;
    var state: i32 = 0;
    var radius: i32 = 0;
    const waterheight: i32 = 1;

    // initialize rand
    var prng = std.rand.DefaultPrng.init(@intCast(deltaTime.timestamp()));
    const rand = prng.random();

    var appRunning: bool = true;

    while (appRunning) {
        // NOTE: There are other ways to use dt for keeping track of render time.
        // This method will lock your update logic to the framerate of the display,
        // and limit the framefrate to a max value determined by tickRate
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0;

            joystick.joystick_init();
            appRunning = !joystick.button_pressed();

            matrix.clearFrame(draw.Color(.BLACK));

            for (0..8) |x| {
                for (0..8) |y| {
                    for (0..(waterheight + 1)) |z| {
                        matrix.setPixel(@intCast(x), @intCast(y), @intCast(z), draw.Color(.TEAL));
                    }
                }
            }

            switch (state) {
                0 => {
                    // START
                    x_start = rand.intRangeAtMost(i32, 0, 7);
                    y_start = rand.intRangeAtMost(i32, 0, 7);
                    matrixSetCheck(x_start, y_start, 7, draw.Color(.TEAL));
                },
                1 => {
                    matrixSetCheck(x_start, y_start, 6, draw.Color(.TEAL));
                },
                2 => {
                    matrixSetCheck(x_start, y_start, 5, draw.Color(.TEAL));
                },
                3 => {
                    matrixSetCheck(x_start, y_start, 4, draw.Color(.TEAL));
                },
                4 => {
                    matrixSetCheck(x_start, y_start, 3, draw.Color(.TEAL));
                },
                5 => {
                    matrixSetCheck(x_start, y_start, 2, draw.Color(.TEAL));
                },
                6 => {
                    // Water droplet hits
                    matrixSetCheck(x_start, y_start, 1, draw.Color(.BLUE));
                    // EXPAND RAD 1
                    // matrixSetCheck(x_start + radius, y_start, 2, draw.Color(.TEAL));
                    // matrixSetCheck(x_start - radius, y_start, 2, draw.Color(.TEAL));
                    // matrixSetCheck(x_start, y_start + radius, 2, draw.Color(.TEAL));
                    // matrixSetCheck(x_start, y_start - radius, 2, draw.Color(.TEAL));
                    // matrixSetCheck(x_start + radius, y_start + radius, 2, draw.Color(.TEAL));
                    // matrixSetCheck(x_start + radius, y_start - radius, 2, draw.Color(.TEAL));
                    // matrixSetCheck(x_start - radius, y_start + radius, 2, draw.Color(.TEAL));
                    // matrixSetCheck(x_start - radius, y_start - radius, 2, draw.Color(.TEAL));
                },
                7 => {
                    matrixSetCheck(x_start, y_start, waterheight + 1, draw.Color(.TEAL));
                    // matrixSetCheck(x_start, y_start, 3, draw.Color(.TEAL));
                    // EXPAND RAD 2
                    matrixSetCheck(x_start + radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start - radius, waterheight, draw.Color(.WHITE));
                },
                8 => {
                    // EXPAND RAD 1
                    matrixSetCheck(x_start + radius - 2, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius - 2, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start + radius - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start - radius - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - radius, waterheight, draw.Color(.WHITE));
                    // EXPAND RAD 3
                    matrixSetCheck(x_start + radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    //rad3 diags
                    matrixSetCheck(x_start + (radius - 1), y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + (radius - 1), y_start - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start - 2, waterheight, draw.Color(.WHITE));
                },
                9 => {
                    // EXPAND RAD 2
                    matrixSetCheck(x_start + (radius - 2), y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + (radius - 2), y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + (radius - 2), y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 2), y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 2), y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 2), y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start + (radius - 2), waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start + (radius - 2), waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start + (radius - 2), waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start - (radius - 2), waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start - (radius - 2), waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start - (radius - 2), waterheight, draw.Color(.WHITE));
                    // EXPAND RAD 4
                    matrixSetCheck(x_start + radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 2, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 2, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 2, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 2, y_start - radius, waterheight, draw.Color(.WHITE));
                    //rad4 diags
                    matrixSetCheck(x_start + (radius - 1), y_start + 3, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + (radius - 1), y_start - 3, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start + 3, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start - 3, waterheight, draw.Color(.WHITE));
                },
                10 => {
                    // EXPAND RAD 3
                    matrixSetCheck(x_start + radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    //rad3 diags
                    matrixSetCheck(x_start + (radius - 1), y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + (radius - 1), y_start - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start - 2, waterheight, draw.Color(.WHITE));
                },
                11 => {
                    // EXPAND RAD 4
                    matrixSetCheck(x_start + radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + radius, y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + 1, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start - 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - radius, y_start + 2, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 2, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 2, y_start + radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 1, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - 2, y_start - radius, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + 2, y_start - radius, waterheight, draw.Color(.WHITE));
                    //rad4 diags
                    matrixSetCheck(x_start + (radius - 1), y_start + 3, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start + (radius - 1), y_start - 3, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start + 3, waterheight, draw.Color(.WHITE));
                    matrixSetCheck(x_start - (radius - 1), y_start - 3, waterheight, draw.Color(.WHITE));
                },
                else => {},
            }

            matrix.render();

            // Change state dependingly
            if (state != 12) {
                if (state == 9) {
                    radius = 3;
                } else if (state > 9) {
                    radius += 1;
                } else if (state > 5) {
                    radius += 1;
                }
                state += 1;
            } else {
                state = 0;
                radius = 0;
            }
        }
    }
}
