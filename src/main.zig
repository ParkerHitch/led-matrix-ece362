const std = @import("std");
const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;
const RCC = microzig.chip.peripherals.RCC;
const LedMatrix = @import("subsystems/matrix.zig");

const TestSR = LedMatrix.SrChain(25, .Div256);

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

const Pattern = enum {
    NOTHING,
    ALL_WHITE,
    ALL_RED,
    ALL_GREEN,
    ALL_BLUE,
    AXIS, // Red on x axis, g on y, b on z, white on origin. Check handedness
    RAINBOW,
};
const numPatterns = @typeInfo(Pattern).Enum.fields.len;

pub fn main() void {
    ChipInit.internal_clock();

    var frame = LedMatrix.Frame{};
    var activePattern: u32 = 0;
    setPattern(&frame, activePattern);

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
    // Clunky. Will clean up later. Didn't realize we had way more data than SRs skull emoji
    TestSR.setup();
    peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .Low });

    var SW3 = DebouncedBtn{};
    var last_state: u1 = 0;

    while (true) {
        for (0..20_000) |_| {
            asm volatile ("nop");
        }
        SW3.update(@intFromEnum(peripherals.GPIOB.IDR.read().@"IDR[2]"));
        if (SW3.state == 1) {
            peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .High });
        } else {
            peripherals.GPIOC.ODR.modify(.{ .@"ODR[6]" = .Low });
        }
        if (SW3.state == 1 and last_state == 0) {
            // increment pattern
            activePattern = (activePattern + 1) % numPatterns;
            setPattern(&frame, activePattern);
            LedMatrix.startShift(&@bitCast(frame));
        }
        last_state = SW3.state;
    }
}

fn setPattern(frame: *LedMatrix.Frame, id: u32) void {
    const newPattern: Pattern = @enumFromInt(id);
    switch (newPattern) {
        .NOTHING => {
            frame.* = LedMatrix.Frame{};
        },
        .ALL_WHITE, .ALL_BLUE, .ALL_GREEN, .ALL_RED => {
            for (0..8) |x| {
                for (0..8) |y| {
                    for (0..8) |z| {
                        frame.set_pixel(@intCast(x), @intCast(y), @intCast(z), switch (newPattern) {
                            .ALL_WHITE => .{ .r = 1, .g = 1, .b = 1 },
                            .ALL_BLUE => .{ .r = 0, .g = 0, .b = 1 },
                            .ALL_GREEN => .{ .r = 0, .g = 1, .b = 0 },
                            .ALL_RED => .{ .r = 1, .g = 0, .b = 0 },
                            else => unreachable,
                        });
                    }
                }
            }
        },
        .AXIS => {
            frame.set_pixel(0, 0, 0, .{ .r = 1, .g = 1, .b = 1 });
            for (1..8) |i| {
                frame.set_pixel(@intCast(i), 0, 0, .{ .r = 1, .g = 0, .b = 0 });
                frame.set_pixel(0, @intCast(i), 0, .{ .r = 0, .g = 1, .b = 0 });
                frame.set_pixel(0, 0, @intCast(i), .{ .r = 0, .g = 0, .b = 1 });
            }
        },
        .RAINBOW => {
            for (0..8) |x| {
                for (0..8) |y| {
                    for (0..8) |z| {
                        const sum: u8 = @intCast(x + y + z);
                        const color: u3 = @intCast(sum & 0b111);
                        frame.set_pixel(@intCast(x), @intCast(y), @intCast(z), @bitCast(color));
                    }
                }
            }
        },
    }
}
