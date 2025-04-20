const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");

pub const app: Application = .{
    .initFn = &init,
    .deinitFn = &deinit,
    .renderFn = &update,
    .name = "Test App",
    .authorfirst = "John",
    .authorlast = "Burns",
};

fn init() callconv(.C) void {}

pub fn update() callconv(.C) void {
    //deltaTime.start();
    //const updateRate: f32 = 1.0; // updates per second
    //var timeSinceUpdate: f32 = 0.0;
    const drawColor = [3]matrix.Led{ .{ .r = 1, .g = 0, .b = 0 }, .{ .r = 0, .g = 1, .b = 0 }, .{ .r = 0, .g = 0, .b = 1 } };
    var drawIdx: u32 = 0;
    var frameCt: u32 = 0;

    while (true) {
        //timeSinceUpdate += deltaTime.get();
        // if (timeSinceUpdate >= updateRate) {
        //     drawIdx = if (drawIdx >= 2) 0 else drawIdx + 1;
        //     timeSinceUpdate = 0.0;
        // }
        if (frameCt % 100 == 0) {
            drawIdx = if (drawIdx >= 2) 0 else drawIdx + 1;
        }
        matrix.clearFrame(drawColor[drawIdx]);

        matrix.render();
        frameCt += 1;
    }
}

fn deinit() callconv(.C) void {}
