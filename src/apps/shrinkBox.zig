const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");

// NOTE: matrix.setPixel and matrix.clearFrame are the only 2
// basic matrix pixel set functions. All future drawing abstractions
// should be placed outside the matrix.zig file, and use setPixel and or clearFrame

// NOTE: helper functions are allowed but should not be pub functions to keep file scope

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Shrink Box",
    .authorfirst = "Micah",
    .authorlast = "Samuel",
};

// app entry point
fn appMain() callconv(.C) void {

    // dt struct is usded for keeping tract of time between frames
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // time keeping vairiables to limit tickRate
    const tickRate: u32 = 15; // i.e. target fps or update rate
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // collision consts
    const boxMaxSize = 8;
    const boxMinSize: comptime_int = 0;
    var boxIsGrowing = true;
    var currSize: i32 = 6;

    // variable for keeping track the color to draw
    var colorIdx: u32 = 0;
    var x_idx: i32 = 1;
    var y_idx: i32 = 1;
    var z_idx: i32 = 1;

    while (true) {
        // NOTE: There are other ways to use dt for keeping track of render time.
        // This method will lock your update logic to the framerate of the display,
        // and limit the framefrate to a max value determined by tickRate
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0;

            // put your app logic here

            // collision detection & resolution
            if (boxIsGrowing) {
                if (currSize == boxMaxSize) {
                    boxIsGrowing = false;
                    currSize -= 2;
                    x_idx += 1;
                    y_idx += 1;
                    z_idx += 1;
                } else {
                    currSize += 2;
                    x_idx -= 1;
                    y_idx -= 1;
                    z_idx -= 1;
                }
            } else {
                if (currSize == boxMinSize) {
                    boxIsGrowing = true;
                    colorIdx = if (colorIdx >= 6) 0 else colorIdx + 1;
                    currSize += 2;
                    x_idx -= 1;
                    y_idx -= 1;
                    z_idx -= 1;
                } else {
                    currSize -= 2;
                    x_idx += 1;
                    y_idx += 1;
                    z_idx += 1;
                }
            }

            // draw to the display
            // NOTE: must start with clearing the frame and end with
            // rendering the frame else the frame before last will remain
            matrix.clearFrame(draw.Color(.BLACK));

            draw.box(x_idx, y_idx, z_idx, currSize, currSize, currSize, draw.Color(@enumFromInt(colorIdx)));

            matrix.render();
        }
    }
}
