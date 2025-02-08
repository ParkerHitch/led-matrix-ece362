const std = @import("std");
const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;

const ChipInit = @import("init/general.zig");

pub fn main() void {
    ChipInit.internal_clock();

    RCC.AHBENR.modify(.{
        .GPIOCEN = 1,
    });

    peripherals.GPIOC.MODER.modify(.{
        .@"MODER[6]" = .Output,
    });

    while (true) {
        for (0..2_000_000) |_| {
            asm volatile ("nop");
        }
        var val = peripherals.GPIOC.ODR.read();
        val.@"ODR[6]" = if (val.@"ODR[6]" == .High) .Low else .High;
        peripherals.GPIOC.ODR.write(val);
    }
}
