const microzig = @import("microzig");
const std = @import("std");
const peripherals = microzig.chip.peripherals;
const periph_types = microzig.chip.types.peripherals;
const RCC = peripherals.RCC;
const DMA2 = peripherals.DMA2;
const SPI1 = peripherals.SPI1;
const GPIOA = peripherals.GPIOA;
const GPIOB = peripherals.GPIOB;
const GPIOC = peripherals.GPIOC;
const TIM2 = peripherals.TIM2;

pub export fn IRQ_DMA1_Ch4_7_DMA2_Ch3_5() callconv(.C) void {
    DMA2.IFCR.modify(.{
        // NOTE: Same bug here. Gotta use 3 instead of 4 cuz microzig has 0
        .@"TCIF[3]" = 1,
    });
    // Set NSS high now that we're done
    GPIOB.ODR.modify(.{
        .@"ODR[4]" = .High,
    });
}

/// A struct representing an SPI interface and an externally-connected timer
/// that feed a chain of 8bit shift registers.
/// Uses SPI1 and TIM2 +
///     pins B3, & 5 for SCLK & MOSI respectively
///     pin A0 & A1 for SCLK input & LE respectively
/// Params:
///     num_srs: the number of 8 bit shift registers in the chain
///     sysclock_divisor: the spi clock is sysclock / 2^(1+divisor)
pub fn SrChain(
    num_leds: comptime_int,
    sysclock_divisor: periph_types.spi_v2.BR,
) type {
    const num_srs = cielDiv(num_leds * 3, 8);
    const bit_count = num_srs * 8;
    return struct {
        const DMA2_CH4: *volatile periph_types.bdma_v2.CH = getDmaCh(DMA2, 4);

        /// Enables & condigures GPIOB
        /// Enables & configures SPI1
        /// Configures, but does not enable DMA2
        pub fn setup() void {
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
                .LSBFIRST = .LSBFirst,
            });
            SPI1.CR2.modify(.{
                .TXDMAEN = 1,
                .SSOE = 1,
                .NSSP = 1,
                .DS = .Bits8,
            });
            // SPI1.CR1.modify(.{
            //     .SPE = 1,
            // });
            // Enable SPI
            const cr1ptr: *volatile u32 = @ptrCast(&SPI1.CR1);
            cr1ptr.* |= 64;

            // Setup TIM2:
            TIM2.SMCR.modify(.{
                .ETP = .Inverted,
                .ECE = 1,
            });
            // ccmr doesn't have a struct for when it's an output
            const ccmr1ptr: *volatile u32 = @ptrCast(&TIM2.CCMR_Input[0]);
            var ccmr1 = ccmr1ptr.*;
            // Clear channel 2
            ccmr1 &= 0xFF;
            // PWM mode 1
            ccmr1 |= 0b111 << 12;
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

            // Setup DMA
            // Configure to respond to SPI requests only
            // See Table 33.
            // NOTE: MICROZIG IS BUGGED!! IT HAS A CS[0] FIELD, SO EVERYTHING IS OFF BY 1 HERE
            // SO EVEN THO WE ARE USING CHANNEL 4, WE GOTTA USE FIELD CS[3]
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
                .CIRC = 0,
                .DIR = .FromMemory,
                .TCIE = 1,
            });

            DMA2_CH4.PAR = @intFromPtr(&SPI1.DR16);
            DMA2_CH4.NDTR.modify(.{
                .NDT = 0,
            });

            // Enable interrupt
            // const ISER: *volatile u32 = @ptrFromInt(0xE000E100);
            // ISER.* = 1 << 11;
        }

        /// Begins an async shift opperation.
        /// Data must remain a valid pointer for the durration of the shift, as DMA will read from it
        pub fn startShift(data: *const [num_srs]u8) void {
            GPIOB.ODR.modify(.{
                .@"ODR[4]" = .Low,
            });
            DMA2_CH4.CR.modify(.{
                .EN = 0,
            });
            DMA2_CH4.MAR = @intFromPtr(data);
            DMA2_CH4.NDTR.modify(.{
                .NDT = num_srs,
            });
            DMA2_CH4.CR.modify(.{
                .EN = 1,
            });
        }

        pub fn sendSync(data: *const [num_srs]u8) void {
            // GPIOB.ODR.modify(.{
            //     .@"ODR[4]" = .Low,
            // });
            for (data) |byte| {
                while (SPI1.SR.read().TXE == 0) {}
                @as(*volatile u8, @ptrCast(&SPI1.DR16)).* = byte;
            }
            // while (SPI1.SR.read().BSY == 1) {}
            // GPIOB.ODR.modify(.{
            //     .@"ODR[4]" = .High,
            // });
        }
    };
}

fn getDmaCh(dma: *volatile periph_types.bdma_v2.DMA, channel: comptime_int) *periph_types.bdma_v2.CH {
    return @ptrFromInt(@intFromPtr(&dma.CH) + 20 * (channel - 1));
}

pub const Led = struct {
    r: u1,
    g: u1,
    b: u1,
};

pub fn LedData(num_leds: comptime_int) type {
    const num_bytes = cielDiv(num_leds * 3, 8);
    const first_bit = num_bytes * 8 - num_leds * 3;

    return struct {
        rawArr: [num_bytes]u8,

        pub fn init_blank() @This() {
            return .{
                .rawArr = .{0} ** num_bytes,
            };
        }

        pub fn set_led(self: *@This(), led_id: u32, val: Led) void {
            self.set_bit(led_id * 3 + first_bit, val.b);
            self.set_bit(led_id * 3 + first_bit + 1, val.g);
            self.set_bit(led_id * 3 + first_bit + 2, val.r);
        }

        pub inline fn set_bit(self: *@This(), bit_id: u32, val: u1) void {
            if (val == 1) {
                self.rawArr[bit_id / 8] |= (@as(u8, 1) << @intCast(bit_id % 8));
            } else {
                self.rawArr[bit_id / 8] &= ~(@as(u8, 1) << @intCast(bit_id % 8));
            }
        }
    };
}

fn cielDiv(a: comptime_int, b: comptime_int) comptime_int {
    var out = a / b;
    if (out * b < a) {
        out += 1;
    }
    return out;
}
