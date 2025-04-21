const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Template Zig App",
    .authorfirst = "John",
    .authorlast = "Burns",
};

pub fn appMain() callconv(.C) void {
    const updateRate: u32 = 1000; // miliseconds per update
    var timeSinceUpdate: u32 = 0;
    const drawColor = [3]matrix.Led{ .{ .r = 1, .g = 0, .b = 0 }, .{ .r = 0, .g = 1, .b = 0 }, .{ .r = 0, .g = 0, .b = 1 } };
    var drawIdx: u32 = 0;
    deltaTime.start();

    while (true) {
        timeSinceUpdate += deltaTime.mili();
        if (timeSinceUpdate >= updateRate) {
            drawIdx = if (drawIdx >= 2) 0 else drawIdx + 1;
            timeSinceUpdate = 0.0;
        }

        matrix.clearFrame(drawColor[drawIdx]);
        matrix.render();
    }
}
