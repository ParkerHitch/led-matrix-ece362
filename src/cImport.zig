const std = @import("std");
const cfiles = @cImport(@cInclude("application.h"));
const matrix = @import("subsystems/matrix.zig");
const cAppNames = @import("options").cApps;

pub const cmsis = @cImport({
    // See: https://ziggit.dev/t/exploring-zig-on-stm32-with-freertos/4653
    // Get's rid of the default _start method and some nasty typedefs
    // This is ok, since microzig provides a _start that initializes .bss and .data for us
    //    (https://github.com/ZigEmbeddedGroup/microzig/blob/bb91614c5a288afd297d5e96ea4fe4d98b5bfba4/core/src/cpus/cortex_m.zig#L251)
    // Really important that this works tho since we are using globals with defined values
    @cDefine("__PROGRAM_START", {});
    @cInclude("stm32f091xc.h");
});

pub const cFrameBuffer = cfiles.FrameBuffer;
pub const cLayerData = cfiles.LayerData;

pub const Application = cfiles.Application;

pub const cApps: [cAppNames.len]*Application = genExtern: {
    var apps: []const *Application = &.{};
    for (cAppNames) |appName| {
        // @compileLog(appName);
        apps = apps ++ .{@extern(*Application, .{ .name = appName })};
    }
    break :genExtern apps[0..cAppNames.len].*;
};

// Externally defined functions
pub extern fn nano_wait(ns: c_uint) void;

// Proper interoperability assertions
comptime {
    std.debug.assert(@sizeOf(matrix.LayerData) == @sizeOf(cLayerData));
    std.debug.assert(@offsetOf(matrix.LayerData, "layerId") == @offsetOf(cLayerData, "layerId"));
    std.debug.assert(@offsetOf(matrix.LayerData, "srs") == @offsetOf(cLayerData, "srs"));
    std.debug.assert(@sizeOf(matrix.FrameBuffer) == @sizeOf(cFrameBuffer));
}
