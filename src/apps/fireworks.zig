const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
//const rand = std.Random; // <-- uncomment for random lib

pub const app: Application = .{
    .renderFn = &renderFireworks,

    .name = "Fireworks",
    .authorfirst = "Richard",
    .authorlast = "Ye",
};

fn renderFireworks() callconv(.C) void {
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
    var randcolor: u32 = 0;

    // initialize rand
    var prng = std.rand.DefaultPrng.init(1625953);
    const rand = prng.random();

    while (true) {
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0;

            matrix.clearFrame(draw.Color(.BLACK));

            switch (state) {
                0 => {
                    // START
                    x_start = rand.intRangeAtMost(i32, 3, 5);
                    y_start = rand.intRangeAtMost(i32, 3, 5);
                    randcolor = rand.intRangeAtMost(u32, 0, 6);
                    matrix.setPixel(x_start, y_start, 0, draw.Color(@enumFromInt(randcolor)));
                },
                1 => {
                    matrix.setPixel(x_start, y_start, 0, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 1, draw.Color(@enumFromInt(randcolor)));
                },
                2 => {
                    matrix.setPixel(x_start, y_start, 1, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 2, draw.Color(@enumFromInt(randcolor)));
                },
                3 => {
                    matrix.setPixel(x_start, y_start, 2, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 3, draw.Color(@enumFromInt(randcolor)));
                },
                4 => {
                    matrix.setPixel(x_start, y_start, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 4, draw.Color(@enumFromInt(randcolor)));
                },
                5 => {
                    matrix.setPixel(x_start, y_start, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                },
                6 => {
                    // SPREAD 1
                    // spread out in same layer
                    matrix.setPixel(x_start, y_start - 1, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start + 1, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 1, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    // dunno if diagonals look good here
                    //top diags
                    matrix.setPixel(x_start + 1, y_start + 1, 6, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start + 1, 6, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 1, y_start - 1, 6, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start - 1, 6, draw.Color(@enumFromInt(randcolor)));
                    // bot diags
                    matrix.setPixel(x_start + 1, y_start + 1, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start + 1, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 1, y_start - 1, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start - 1, 4, draw.Color(@enumFromInt(randcolor)));
                    // diagonals end
                    matrix.setPixel(x_start, y_start, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 6, draw.Color(@enumFromInt(randcolor)));
                },
                7 => {
                    // SPREAD 1 REPEATS
                    // spread out in same layer
                    matrix.setPixel(x_start, y_start - 1, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start + 1, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 1, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    // dunno if diagonals look good here
                    //top diags
                    matrix.setPixel(x_start + 1, y_start + 1, 6, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start + 1, 6, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 1, y_start - 1, 6, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start - 1, 6, draw.Color(@enumFromInt(randcolor)));
                    // bot diags
                    matrix.setPixel(x_start + 1, y_start + 1, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start + 1, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 1, y_start - 1, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 1, y_start - 1, 4, draw.Color(@enumFromInt(randcolor)));
                    // diagonals end
                    matrix.setPixel(x_start, y_start, 4, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 6, draw.Color(@enumFromInt(randcolor)));

                    // SPREAD 2
                    matrix.setPixel(x_start, y_start - 2, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start + 2, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    // dunno if diagonals look good here
                    //top diags
                    matrix.setPixel(x_start + 2, y_start + 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start + 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start - 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start - 2, 7, draw.Color(@enumFromInt(randcolor)));
                    // bot diags
                    matrix.setPixel(x_start + 2, y_start + 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start + 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start - 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start - 2, 3, draw.Color(@enumFromInt(randcolor)));
                    // diagonals end
                    matrix.setPixel(x_start, y_start, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 7, draw.Color(@enumFromInt(randcolor)));
                },
                8 => {
                    // SPREAD 2 LINGERS
                    matrix.setPixel(x_start, y_start - 2, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start + 2, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    // dunno if diagonals look good here
                    //top diags
                    matrix.setPixel(x_start + 2, y_start + 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start + 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start - 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start - 2, 7, draw.Color(@enumFromInt(randcolor)));
                    // bot diags
                    matrix.setPixel(x_start + 2, y_start + 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start + 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start - 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start - 2, 3, draw.Color(@enumFromInt(randcolor)));
                    // diagonals end
                    matrix.setPixel(x_start, y_start, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 7, draw.Color(@enumFromInt(randcolor)));
                },
                9 => {
                    // SPREAD 2 LINGERS AGAIN
                    matrix.setPixel(x_start, y_start - 2, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start + 2, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start, 5, draw.Color(@enumFromInt(randcolor)));
                    // dunno if diagonals look good here
                    //top diags
                    matrix.setPixel(x_start + 2, y_start + 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start + 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start - 2, 7, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start - 2, 7, draw.Color(@enumFromInt(randcolor)));
                    // bot diags
                    matrix.setPixel(x_start + 2, y_start + 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start + 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start + 2, y_start - 2, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start - 2, y_start - 2, 3, draw.Color(@enumFromInt(randcolor)));
                    // diagonals end
                    matrix.setPixel(x_start, y_start, 3, draw.Color(@enumFromInt(randcolor)));
                    matrix.setPixel(x_start, y_start, 7, draw.Color(@enumFromInt(randcolor)));
                },
                else => {
                    matrix.clearFrame(draw.Color(.RED));
                },
            }
            matrix.render();

            // Change state dependingly
            if (state != 9) {
                state += 1;
            } else {
                state = 0;
            }
            // matrix.setPixel(FrameBuffer* frame, uint8_t x, uint8_t y, uint8_t z, uint8_t color);
        }
    }
}
