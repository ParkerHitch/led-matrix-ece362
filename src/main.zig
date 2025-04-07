const std = @import("std");
const microzig = @import("microzig");
const LedMatrix = @import("subsystems/matrix.zig");
const cImport = @import("cImport.zig");
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;
const FrameBuffer = LedMatrix.FrameBuffer;

const ChipInit = @import("init/general.zig");

pub const microzig_options = .{
    .interrupts = .{
        .DMA1_Ch4_7_DMA2_Ch3_5 = microzig.interrupt.Handler{ .C = LedMatrix.IRQ_DMA1_Ch4_7_DMA2_Ch3_5 },
    },
};

comptime {
    _ = @import("cExport.zig");
}

pub fn main() void {
    ChipInit.internal_clock();

    var buffer1: FrameBuffer = .{};
    var buffer2: FrameBuffer = .{};
    var currentBuffer = &buffer1;

    while (true) {
        cImport.cApps[0].renderFn.?(currentBuffer.cPtr());

        if (currentBuffer == &buffer1) {
            currentBuffer = &buffer2;
        } else {
            currentBuffer = &buffer1;
        }
        // TODO:
        // Render
    }
}
