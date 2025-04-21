const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Template Zig App",
    .authorfirst = "John",
    .authorlast = "Burns",
};

pub fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();
    const tickRate: u32 = 1; // i.e. target fps
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    var drawIdx: u32 = 0;

    while (true) {
        timeSinceUpdate += dt.mili();
        if (timeSinceUpdate >= updateTime) {
            drawIdx = if (drawIdx >= 7) 0 else drawIdx + 1;
            timeSinceUpdate = 0.0;

            matrix.clearFrame(draw.Color(@enumFromInt(drawIdx)));
            matrix.render();
        }
    }
}
