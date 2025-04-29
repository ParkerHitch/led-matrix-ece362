/// matrix.zig
/// The subsystem responsible for displaying to the cube.
/// Consists of an SPI interface and an SCLK-driven timer that feed a chain of 8bit shift registers.
/// Uses SPI1 and TIM2 +
///     pins B3, & 5 for SCLK & MOSI respectively
///     pin A0 & A1 for SCLK input & LE respectively
const microzig = @import("microzig");
const std = @import("std");
const math = std.math;
const cImport = @import("../cImport.zig");
const UartdDebug = @import("../util/uartDebug.zig");
const cmsis = cImport.cmsis;
const peripherals = microzig.chip.peripherals;
const periph_types = microzig.chip.types.peripherals;
const RCC = peripherals.RCC;
const DMA2 = peripherals.DMA2;
const DMA2_CH4: *volatile periph_types.bdma_v2.CH = getDmaCh(DMA2, 4);
const SPI1 = peripherals.SPI1;
const GPIOA = peripherals.GPIOA;
const GPIOB = peripherals.GPIOB;
const GPIOC = peripherals.GPIOC;
const TIM2 = peripherals.TIM2;
const TIM15 = peripherals.TIM15;

pub const upperBound: comptime_int = 7;
pub const lowerBound: comptime_int = 0;

pub const BAM_bits = 3;
// Max time that it should take to do every BAM phase (MSB, ..., LSB)
// Sum of time spent on all bits will be about equal to this, but stuff can go wrong so build in some safety here.
pub const BAM_max_time: comptime_float = 1.0 / 80.0;
pub const BAM_lsb_time = BAM_max_time / @as(comptime_float, (1 << BAM_bits - 1.0));
pub const BAM_lsb_time_us: usize = @floor(BAM_lsb_time * 1_000_000);
comptime {
    // Time to shift out stuff + a safety factor of 10%
    std.debug.assert(BAM_lsb_time > (1.0 / 4_000_000.0) * 200 * 1.1);
    std.debug.assert(BAM_lsb_time_us << (BAM_bits - 1) <= math.maxInt(u16));
}

// Frame buffers for rendering
var frameBuff1: FrameBuffer = .{};
var frameBuff2: FrameBuffer = .{};
var drawBuff: *FrameBuffer = &frameBuff1; // buffer that isn't currently being rendered

pub export fn IRQ_DMA1_Ch4_7_DMA2_Ch3_5() callconv(.C) void {
    DMA2.IFCR.modify(.{
        // NOTE: Same bug here. Gotta use 3 instead of 4 cuz microzig has 0
        .@"TCIF[3]" = 1,
    });
}

/// Setup the display
/// Params:
///     sysclock_divisor: an enum of the form .Div2 to .Div256 (powers of 2)
///         default should be .Div4
///         SCLK will have a frequency of sysclock (48 Mhz) divided by this number
pub fn init(sysclock_divisor: periph_types.spi_v2.BR) void {
    const num_srs = 25;
    const bit_count = num_srs * 8;
    // Enable clocks
    RCC.AHBENR.modify(.{
        .DMA2EN = 1,
        .GPIOAEN = 1,
        .GPIOBEN = 1,
    });
    RCC.APB1ENR.modify(.{
        .TIM2EN = 1,
    });
    RCC.APB2ENR.modify(.{
        .TIM15EN = 1,
    });
    RCC.APB2ENR.modify(.{
        .SPI1EN = 1,
    });

    // Setup GPIOB
    GPIOB.MODER.modify(.{
        .@"MODER[3]" = .Alternate,
        .@"MODER[5]" = .Alternate,
    });
    GPIOB.AFR[0].modify(.{
        .@"AFR[3]" = 0,
        .@"AFR[5]" = 0,
    });
    GPIOB.OSPEEDR.modify(.{
        .@"OSPEEDR[3]" = .VeryHighSpeed,
        .@"OSPEEDR[5]" = .VeryHighSpeed,
    });

    // Setup GPIOA
    GPIOA.MODER.modify(.{
        .@"MODER[0]" = .Alternate,
        .@"MODER[1]" = .Alternate,
    });
    GPIOA.AFR[0].modify(.{
        .@"AFR[0]" = 2,
        .@"AFR[1]" = 2,
    });

    // Setup SPI1
    SPI1.CR1.modify(.{
        .SPE = 0,
    });
    SPI1.CR1.modify(.{
        .CPHA = .FirstEdge,
        .CPOL = .IdleLow,
        .MSTR = .Master,
        .BR = sysclock_divisor,
        .LSBFIRST = .MSBFirst,
    });
    SPI1.CR2.modify(.{
        .TXDMAEN = 1,
        .SSOE = 1,
        .NSSP = 1,
        .DS = .Bits8,
    });
    // Enable SPI
    SPI1.CR1.modify(.{
        .SPE = 1,
    });

    // Setup TIM2:
    TIM2.SMCR.modify(.{
        .ETP = .Inverted,
        .ECE = 1,
    });
    // ccmr doesn't have a struct for when it's an output
    const ccmr1ptr: *volatile u32 = @ptrCast(&TIM2.CCMR_Input[0]);
    var ccmr1 = ccmr1ptr.*;
    // Clear everything to do with channel 2
    ccmr1 &= ~(cmsis.TIM_CCMR1_CC2S | cmsis.TIM_CCMR1_OC2FE | cmsis.TIM_CCMR1_OC2PE | cmsis.TIM_CCMR1_OC2CE);
    // PWM mode 2
    ccmr1 |= cmsis.TIM_CCMR1_OC2M_Msk;
    ccmr1ptr.* = ccmr1;
    TIM2.PSC = 0;
    TIM2.ARR = bit_count - 1;
    // Because of pwm mode 2, we are high when count >= CCR, so LE goes high when = bit count, then it resets
    TIM2.CCR[1] = bit_count - 1;
    TIM2.CCER.modify(.{
        .@"CCE[1]" = 1,
    });
    TIM2.CR1.modify(.{
        .CEN = 1,
    });

    // TIM15 (for BAM)
    // 48 Mhz to us = 48
    TIM15.PSC = 48 - 1;
    TIM15.CR1.modify(.{
        .OPM = 1,
        .CEN = 0,
    });
    TIM15.DIER.modify(.{
        .UIE = 1,
    });
    cmsis.NVIC.*.ISER[0] |= @as(u32, 1 << cmsis.TIM15_IRQn);

    // Setup DMA
    // Configure to respond to SPI requests only
    // See Table 33.
    // NOTE: MICROZIG IS BUGGED!! IT HAS A CS[0] FIELayerData, SO EVERYTHING IS OFF BY 1 HERE
    // SO EVEN THO WE ARE USING CHANNEL 4, WE GOTTA USE FIELayerData CS[3]
    DMA2.CSELR.modify(.{
        .@"CS[3]" = 0b0011,
    });

    DMA2_CH4.CR.modify(.{
        // Do not enable yet
        .EN = 0,
        .PSIZE = .Bits8,
        .MSIZE = .Bits8,
        .PL = .VeryHigh,
        .MINC = 1,
        .CIRC = 1,
        .DIR = .FromMemory,
        .TCIE = 1,
    });

    DMA2_CH4.PAR = @intFromPtr(&SPI1.DR16);
    DMA2_CH4.NDTR.modify(.{
        .NDT = 0,
    });

    // Enable interrupt
    // cmsis.NVIC_EnableIRQ(cmsis.DMA1_Ch4_7_DMA2_Ch3_5_IRQn);

    clearFrame(.{ .r = 0, .g = 0, .b = 0 });
    render();
}

/// Begins an async shift opperation.
/// Data must remain a valid pointer for the durration of the shift, as DMA will read from it
pub fn startShift(data: *const FrameBuffer) void {
    comptime std.debug.assert(@sizeOf(FrameBuffer) == (25 * 8));
    DMA2_CH4.CR.modify(.{
        .EN = 0,
    });
    TIM2.CR1.modify(.{
        .CEN = 0,
    });
    // Wait for SPI to finish
    while (SPI1.SR.read().BSY == 1) {}

    DMA2_CH4.MAR = @intFromPtr(data);
    DMA2_CH4.NDTR.modify(.{
        .NDT = @sizeOf(FrameBuffer),
    });
    TIM2.CNT = 0;
    TIM2.CR1.modify(.{
        .CEN = 1,
    });

    DMA2_CH4.CR.modify(.{
        .EN = 1,
    });
}

fn getDmaCh(dma: *volatile periph_types.bdma_v2.DMA, channel: comptime_int) *periph_types.bdma_v2.CH {
    return @ptrFromInt(@intFromPtr(&dma.CH) + 20 * (channel - 1));
}

pub const Led = packed struct {
    r: u1,
    g: u1,
    b: u1,
};

const Color = enum { R, G, B };

pub const LayerData = extern struct {
    layerId: u8,
    srs: [24]u8 = .{0} ** 24,
};

pub const FrameBuffer = extern struct {
    layers: [8]LayerData = defaultLayers: {
        var layers: [8]LayerData = .{LayerData{ .layerId = 0 }} ** 8;
        for (0..8) |i| {
            layers[7 - i].layerId = i; // NOTE: hardware inverted z

        }
        break :defaultLayers layers;
    },

    /// Right-handed coordinates where z is up
    pub fn set_pixel(self: *FrameBuffer, x: i32, y: i32, z: i32, color: Led) void {
        const layer: *LayerData = &self.layers[@intCast(z)];
        const newY: i32 = 7 - y;
        const offset: i32 = 3 * newY;
        const row: []u8 = layer.srs[@intCast(offset)..];
        const rawColor: u8 = @intCast(@as(u3, @bitCast(color)));
        switch (x) {
            0 => {
                row[0] &= ~@as(u8, 0x7);
                row[0] |= rawColor;
            },
            1 => {
                row[0] &= ~@as(u8, 0x38);
                row[0] |= rawColor << 3;
            },
            2 => {
                row[0] &= ~@as(u8, 0xC0);
                row[0] |= rawColor << 6;
                row[1] &= ~@as(u8, 0x1);
                row[1] |= rawColor >> 2;
            },
            3 => {
                row[1] &= ~@as(u8, 0x0e);
                row[1] |= rawColor << 1;
            },
            4 => {
                row[1] &= ~@as(u8, 0x70);
                row[1] |= rawColor << 4;
            },
            5 => {
                row[1] &= ~@as(u8, 0x80);
                row[1] |= rawColor << 7;
                row[2] &= ~@as(u8, 0x03);
                row[2] |= rawColor >> 1;
            },
            6 => {
                row[2] &= ~@as(u8, 0x1c);
                row[2] |= rawColor << 2;
            },
            7 => {
                row[2] &= ~@as(u8, 0xe0);
                row[2] |= rawColor << 5;
            },
            else => {},
        }
    }

    pub fn set_channel(self: *FrameBuffer, x: u3, y: u3, z: u3, channel: Color, val: u1) void {
        const bitoffset: u8 = (x * 3 + @intFromEnum(channel));
        const srptr: *u8 = &self.layers[z].srs[bitoffset / 8 + (3 * (7 - y))];

        srptr.* &= ~(@as(u8, 1) << @intCast(bitoffset % 8));
        srptr.* |= (@as(u8, val) << @intCast(bitoffset % 8));
    }

    pub fn cPtr(self: *FrameBuffer) *cImport.cFrameBuffer {
        return @ptrCast(self);
    }
};

pub fn clearFrame(color: Led) void {
    for (0..8) |x| {
        for (0..8) |y| {
            for (0..8) |z| {
                drawBuff.set_pixel(@intCast(x), @intCast(y), @intCast(z), color);
            }
        }
    }
}

pub fn setPixel(x: i32, y: i32, z: i32, color: Led) void {
    drawBuff.set_pixel(x, y, z, color);
}

pub fn render() callconv(.C) void {
    startShift(drawBuff);
    drawBuff = if (drawBuff == &frameBuff1) &frameBuff2 else &frameBuff1;
}

const BamBitInd = std.math.IntFittingRange(0, BAM_bits - 1);
var BAM_buff1 = BAM_buff{};
var BAM_buff2 = BAM_buff{};
var BAM_renderBuff = &BAM_buff1;
var BAM_drawBuff = &BAM_buff2;

var BAM_currentBitRaw: BamBitInd = 0;
var BAM_frameSwitchPendingRaw: bool = false;
var BAM_stopPendingRaw: bool = false;
const BAM_currentBit: *volatile BamBitInd = @volatileCast(&BAM_currentBitRaw);
const BAM_frameSwitchPending: *volatile bool = @volatileCast(&BAM_frameSwitchPendingRaw);
const BAM_stopPending: *volatile bool = @volatileCast(&BAM_stopPendingRaw);

pub const BAM_int = std.meta.Int(.unsigned, BAM_bits);

pub const BAM_color = struct {
    r: BAM_int,
    g: BAM_int,
    b: BAM_int,
};

pub const BAM_buff = struct {
    levels: [BAM_bits]FrameBuffer = .{FrameBuffer{}} ** BAM_bits,

    pub fn set_pixel(self: *BAM_buff, x: u3, y: u3, z: u3, value: BAM_color) void {
        for (0..BAM_bits) |i_| {
            const i: BamBitInd = @intCast(i_);
            self.levels[i].set_pixel(x, y, z, Led{
                .r = @intCast((value.r >> i) & 0b1),
                .g = @intCast((value.g >> i) & 0b1),
                .b = @intCast((value.b >> i) & 0b1),
            });
        }
    }
};

pub fn enableBAM() void {
    BAM_currentBit.* = 0;
    TIM15_IRQ();
}

pub fn disableBAM() void {
    BAM_stopPending.* = true;
    while (BAM_stopPending.*) {
        asm volatile ("wfi");
    }
}

pub fn setPixelBAM(x: i32, y: i32, z: i32, color: BAM_color) void {
    BAM_drawBuff.set_pixel(@intCast(x), @intCast(y), @intCast(z), color);
}

pub fn clearFrameBAM(color: BAM_color) void {
    _ = color;
}

pub fn renderBAM() void {
    BAM_frameSwitchPending.* = true;
    while (BAM_frameSwitchPending.*) {
        asm volatile ("nop");
    }
}

pub export fn TIM15_IRQ() callconv(.C) void {
    TIM15.SR.modify(.{ .UIF = 0 });
    // UartdDebug.printIfDebug("Tim15 hit. Current bit: {}\n", .{BAM_currentBit.*}) catch {};
    std.debug.assert(TIM15.CR1.read().CEN == 0);
    if (BAM_currentBit.* == BAM_bits - 1) {
        BAM_currentBit.* = 0;
        if (BAM_frameSwitchPending.*) {
            const temp = BAM_renderBuff;
            BAM_renderBuff = BAM_drawBuff;
            BAM_drawBuff = temp;
            BAM_frameSwitchPending.* = false;
        }
    } else {
        BAM_currentBit.* += 1;
    }
    DMA2_CH4.CR.modify(.{
        .EN = 0,
    });
    TIM2.CR1.modify(.{
        .CEN = 0,
    });

    while (SPI1.SR.read().BSY == 1) {}
    if (BAM_stopPending.*) {
        BAM_stopPending.* = false;
        return;
    }

    DMA2_CH4.MAR = @intFromPtr(&BAM_renderBuff.levels[BAM_currentBit.*]);
    DMA2_CH4.NDTR.modify(.{
        .NDT = @sizeOf(FrameBuffer),
    });
    TIM2.CNT = 0;
    TIM2.CR1.modify(.{
        .CEN = 1,
    });
    DMA2_CH4.CR.modify(.{
        .EN = 1,
    });

    TIM15.CNT = @bitCast(@as(u32, 0));
    TIM15.ARR = @bitCast(BAM_lsb_time_us << BAM_currentBit.*);
    TIM15.DIER.modify(.{
        .UIE = 1,
    });
    TIM15.CR1.modify(.{
        .CEN = 1,
    });
}

// Way harder to put this inside a test block, as those need to run on the machine, which is the microcontroller
// Random comptime block works just as well for this memory layout stuff
comptime {
    // Assert that our layers have the correct memory map
    std.debug.assert(@import("builtin").target.cpu.arch.endian() == std.builtin.Endian.little);
    std.debug.assert(@sizeOf(LayerData) == 25);
    std.debug.assert(@offsetOf(LayerData, "layerId") == 0);
    std.debug.assert(@offsetOf(LayerData, "srs") == 1);
    // Assert that our frames have the correct memory map
    std.debug.assert(@sizeOf(FrameBuffer) == 25 * 8);
}

comptime {
    var frame: FrameBuffer = .{};
    frame.set_pixel(2, 7, 0, .{ .r = 1, .g = 1, .b = 1 });
    // @compileLog(frame.layers[0].srs);
    std.debug.assert(frame.layers[0].layerId == 7); // NOTE: hardware inverted z
    std.debug.assert(frame.layers[0].srs[0] == 0xC0);
    std.debug.assert(frame.layers[0].srs[1] == 0x01);
}

fn cielDiv(a: comptime_int, b: comptime_int) comptime_int {
    var out = a / b;
    if (out * b < a) {
        out += 1;
    }
    return out;
}
