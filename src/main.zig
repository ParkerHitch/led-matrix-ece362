const std = @import("std");
const microzig = @import("microzig");
const LedMatrix = @import("subsystems/matrix.zig");
const cImport = @import("cImport.zig");
const Application = cImport.Application;
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;
const FrameBuffer = LedMatrix.FrameBuffer;
const zigApps = @import("apps/index.zig").zigApps;
const ChipInit = @import("init/general.zig");
// Make sure everything gets exported
comptime {
    _ = @import("cExport.zig");
}

pub const microzig_options = .{
    .interrupts = .{
        .DMA1_Ch4_7_DMA2_Ch3_5 = microzig.interrupt.Handler{ .C = LedMatrix.IRQ_DMA1_Ch4_7_DMA2_Ch3_5 },
    },
};

pub const apps = zigApps ++ cImport.cApps;

pub fn main() void {
    ChipInit.internal_clock();

    LedMatrix.init(.Div4);

    var buffer1: FrameBuffer = .{};
    var buffer2: FrameBuffer = .{};
    var currentBuffer = &buffer1;

    while (true) {
        apps[0].renderFn.?();

        if (currentBuffer == &buffer1) {
            currentBuffer = &buffer2;
        } else {
            currentBuffer = &buffer1;
        }
        // TODO:
        // Render
    }
}
