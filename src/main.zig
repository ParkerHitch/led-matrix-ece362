const std = @import("std");
const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;
const LedMatrix = @import("subsystems/matrix.zig");

const TestSR = LedMatrix.SrChain(8, .Div4);

const ChipInit = @import("init/general.zig");

pub const microzig_options = .{
    .interrupts = .{
        .DMA1_Ch4_7_DMA2_Ch3_5 = microzig.interrupt.Handler{ .C = LedMatrix.IRQ_DMA1_Ch4_7_DMA2_Ch3_5 },
    },
};

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

    var frame = LedMatrix.Frame{};

    RCC.AHBENR.modify(.{
        .GPIOBEN = 1,
        .GPIOCEN = 1,
    });

    peripherals.GPIOC.MODER.modify(.{
        .@"MODER[6]" = .Output,
        .@"MODER[7]" = .Output,
    });
    peripherals.GPIOB.MODER.modify(.{
        .@"MODER[2]" = .Input,
    });
    peripherals.GPIOB.PUPDR.modify(.{
        .@"PUPDR[2]" = .PullDown,
    });

    peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .High });
    TestSR.setup();
    peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .Low });

    var SW3 = DebouncedBtn{};
    var last_state: u1 = 0;
    var id: u3 = 0;

    while (true) {
        for (0..150_000) |_| {
            asm volatile ("nop");
        }
        SW3.update(@intFromEnum(peripherals.GPIOB.IDR.read().@"IDR[2]"));
        if (SW3.state == 1) {
            peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .High });
        } else {
            peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .Low });
        }
        if (SW3.state == 1 and last_state == 0) {
            TestSR.startShift(frame.layers[0].srs[0..3]);
            // if (true) {
            // ledData.set_led(id +% 7, .{ .r = 0, .g = 0, .b = 0 });
            // ledData.set_led(id +% 6, .{ .r = 1, .g = 0, .b = 0 });
            // ledData.set_led(id +% 5, .{ .r = 1, .g = 1, .b = 0 });
            // ledData.set_led(id +% 4, .{ .r = 0, .g = 1, .b = 0 });
            // ledData.set_led(id +% 3, .{ .r = 0, .g = 1, .b = 1 });
            // ledData.set_led(id +% 2, .{ .r = 0, .g = 0, .b = 1 });
            // ledData.set_led(id +% 1, .{ .r = 1, .g = 0, .b = 1 });
            // ledData.set_led(id +% 0, .{ .r = 1, .g = 1, .b = 1 });
            // TestSR.startShift(&ledData.rawArr);
            // Wrapping addition
            id -%= 1;
        }
        last_state = SW3.state;
    }
}

pub fn snek(frame: LedMatrix.Frame, red: u1, green: u1, blue: u1) void {
    var x: u3 = 0;
    var y: u3 = 0;
    var z: u3 = 0;

    while (z < 8) {
        while (y < 8) {
            while (x < 8) {
                frame.set_pixel(x, y, z, .{ .r = red, .g = green, .b = blue });
                x += 1;
            }
            y += 1;
            x = 0;
        }
        z += 1;
        y = 0;
    }
}
