const Application = @import("../cImport.zig").Application;
const std = @import("std");
// const zigAppNames = @import("options").zigApps;

pub const zigApps = [_]*const Application{
    &@import("templateApp.zig").app,
    &@import("axisApp.zig").app,
    &@import("tesseract.zig").app,
    &@import("dvdApp.zig").app,
    &@import("fireworks.zig").app,
};

// comptime {
//     // TODO:
//     // Use these options to auto-getnerate this file
//     std.debug.assert(zigApps.len == @import("options").zigApps.len);
// }
