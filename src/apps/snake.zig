const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const rand = std.Random;

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "3D Snake",
    .authorfirst = "John",
    .authorlast = "Burns",
};

const appState = struct {
    updateTime: u32,
    timeSinceUpdate: u32 = 0,
};

fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    const tickRate: u32 = 24; // i.e. target fps or update rate
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // variable for keeping track the color to draw

    // TODO: replace true in while true with joystick press exit condition
    while (true) {
        // NOTE: There are other ways to use dt for keeping track of render time.
        // This method will lock your update logic to the framerate of the display,
        // and limit the framefrate to a max value determined by tickRate
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0;

            // draw to the display
            // NOTE: must start with clearing the frame and end with
            // rendering the frame else the frame before last will remain
            matrix.clearFrame(draw.Color(.BLACK));

            matrix.render();
        }
    }
}
