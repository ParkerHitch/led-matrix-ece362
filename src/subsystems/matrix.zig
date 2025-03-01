const microzig = @import("microzig");
const std = @import("std");
const peripherals = microzig.chip.peripherals;
const periph_types = microzig.chip.types.peripherals;
const RCC = peripherals.RCC;
const DMA2 = peripherals.DMA2;
const SPI1 = peripherals.SPI1;
const GPIOB = peripherals.GPIOB;
const GPIOC = peripherals.GPIOC;

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

/// A struct representing an SPI interface to a chain of 8bit shift registers
/// uses SPI1, pins B3, 4, & 5 for SCLK, NSS/LE, & MOSI respectively
///     num_srs: the number of 8 bit shift registers in the chain
///     sysclock_divisor: the spi clock is sysclock / 2^(1+divisor)
pub fn SrChain(
    num_srs: comptime_int,
    sysclock_divisor: u3,
) type {
    return struct {
        const DMA2_CH4: *volatile periph_types.bdma_v2.CH = getDmaCh(DMA2, 4);

        /// Enables & condigures GPIOB
        /// Enables & configures SPI1
        /// Configures, but does not enable DMA2
        pub fn setup() void {
            // Enable clocks
            RCC.AHBENR.modify(.{
                .DMA2EN = 1,
                .GPIOBEN = 1,
            });
            RCC.APB2ENR.modify(.{
                .SPI1EN = 1,
            });

            // Setup GPIOB
            GPIOB.MODER.modify(.{
                .@"MODER[3]" = .Alternate,
                .@"MODER[4]" = .Output,
                .@"MODER[5]" = .Alternate,
            });
            GPIOB.AFR[1].modify(.{
                .@"AFR[3]" = 0,
                .@"AFR[5]" = 0,
            });
            GPIOB.ODR.modify(.{
                .@"ODR[4]" = .High,
            });

            // Setup SPI1
            SPI1.CR1.modify(.{
                .SPE = 0,
            });
            SPI1.CR1.modify(.{
                .CPHA = .FirstEdge,
                .CPOL = .IdleLow,
                .MSTR = .Master,
                .BR = @as(periph_types.spi_v2.BR, @enumFromInt(sysclock_divisor)),
                .LSBFIRST = .MSBFirst,
            });
            SPI1.CR2.modify(.{
                .TXDMAEN = 1,
                .SSOE = 1,
                .NSSP = 1,
                .DS = .Bits8,
            });
            const cr1ptr: *volatile u32 = @ptrCast(&SPI1.CR1);
            cr1ptr.* |= 64;

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
            const ISER: *volatile u32 = @ptrFromInt(0xE000E100);
            ISER.* = 1 << 11;
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
            GPIOB.ODR.modify(.{
                .@"ODR[4]" = .Low,
            });
            for (data) |byte| {
                while (SPI1.SR.read().TXE == 0) {}
                @as(*volatile u8, @ptrCast(&SPI1.DR16)).* = byte;
            }
            GPIOB.ODR.modify(.{
                .@"ODR[4]" = .High,
            });
        }
    };
}

fn getDmaCh(dma: *volatile periph_types.bdma_v2.DMA, channel: comptime_int) *periph_types.bdma_v2.CH {
    return @ptrFromInt(@intFromPtr(&dma.CH) + 20 * (channel - 1));
}
