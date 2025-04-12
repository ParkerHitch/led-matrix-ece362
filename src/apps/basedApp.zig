const Application = @import("../cImport.zig").Application;

pub const app: Application = .{
    .initFn = &init,
    .deinitFn = &deinit,
    .renderFn = &update,
    .name = "Based App",
    .author = "Some zig chad",
};

fn init() callconv(.C) void {}

fn update() callconv(.C) void {}

fn deinit() callconv(.C) void {}
