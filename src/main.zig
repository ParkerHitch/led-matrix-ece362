const std = @import("std");
const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;
const LedMatrix = @import("subsystems/matrix.zig");
const TestSR = LedMatrix.SrChain(2, 0b111);

const ChipInit = @import("init/general.zig");

const DebouncedBtn = struct {
    history: u8 = 0,
    state: u1 = 0,

    pub fn update(self: *@This(), val: u1) void {
        self.history = (self.history << 1) | val;
        if (self.history == 0xFF) {
            self.state = 1;
        } else if (self.history == 0x00) {
            self.state = 0;
        }
    }
};

pub fn main() void {
    ChipInit.internal_clock();

    TestSR.setup();

    // const p: u8 = get_peen(0);
    // if (p != 'p') {
    //     return;
    // }

    RCC.AHBENR.modify(.{
        .GPIOBEN = 1,
        .GPIOCEN = 1,
    });

    peripherals.GPIOC.MODER.modify(.{
        .@"MODER[6]" = .Output,
    });
    peripherals.GPIOB.MODER.modify(.{
        .@"MODER[2]" = .Input,
    });
    peripherals.GPIOB.PUPDR.modify(.{
        .@"PUPDR[2]" = .PullDown,
    });

    var SW3 = DebouncedBtn{};
    var last_state: u1 = 0;
    var id: u3 = 0;

    while (true) {
        for (0..10_000) |_| {
            asm volatile ("nop");
        }
        SW3.update(@intFromEnum(peripherals.GPIOB.IDR.read().@"IDR[2]"));
        if (SW3.state == 1) {
            peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .High });
        } else {
            peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .Low });
        }
        if (SW3.state == 1 and last_state == 0) {
            TestSR.startShift(&.{ id, 0x7F });
            // Wrapping addition
            id +%= 1;
        }
        last_state = SW3.state;
    }
}
