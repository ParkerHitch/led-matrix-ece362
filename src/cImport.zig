const std = @import("std");
const cfiles = @cImport(@cInclude("application.h"));
const matrix = @import("subsystems/matrix.zig");

pub const cFrameBuffer = cfiles.FrameBuffer;
pub const cLayerData = cfiles.LayerData;

pub const Application = cfiles.Application;

pub const cApps: [1]*Application = .{@extern(*Application, .{ .name = "myApp" })};

// Proper interoperability assertions
comptime {
    std.debug.assert(@sizeOf(matrix.LayerData) == @sizeOf(cLayerData));
    std.debug.assert(@offsetOf(matrix.LayerData, "layerId") == @offsetOf(cLayerData, "layerId"));
    std.debug.assert(@offsetOf(matrix.LayerData, "srs") == @offsetOf(cLayerData, "srs"));
    std.debug.assert(@sizeOf(matrix.FrameBuffer) == @sizeOf(cFrameBuffer));
}
