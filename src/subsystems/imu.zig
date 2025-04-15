const std = @import("std");
const microzig = @import("microzig");
const cmsis = @import("../cImport.zig").cmsis;
const peripherals = microzig.chip.peripherals;
const periph_types = microzig.chip.types.peripherals;
const I2C1 = peripherals.I2C1;
const GPIOA = peripherals.GPIOA;
const RCC = peripherals.RCC;

const ACCEL_ADDR = 0x69;
const MAG_ADDR = 0x0c;

pub const Device = enum { Accel, Mag };

pub fn init() void {
    RCC.AHBENR.modify(.{
        .GPIOAEN = 1,
    });
    RCC.APB1ENR.modify(.{
        .I2C1EN = 1,
    });

    // Disable peripheral
    I2C1.CR1.modify(.{ .PE = 0 });

    // Set clock source as 48 mhz
    RCC.CFGR3.modify(.{
        .I2C1SW = .SYS,
    });

    // Turn on analog filtering and off digital filtering
    I2C1.CR1.modify(.{
        .ANFOFF = 0,
        .DNF = .NoFilter,
    });

    // Values from Table 95: "Examples of timings settings for f_I2CCLK = 48 MHz"
    I2C1.TIMINGR.modify(.{
        .PRESC = 5,
        .SCLL = 0x9,
        .SCLH = 0x3,
        .SDADEL = 0x3,
        .SCLDEL = 0x3,
    });

    // Must be unset when in master
    I2C1.CR1.modify(.{
        .NOSTRETCH = 0,
    });

    // ===========
    // Setup GPIOA
    // ===========
    GPIOA.MODER.modify(.{
        .@"MODER[9]" = .Alternate,
        .@"MODER[10]" = .Alternate,
    });
    // AFR[1] gives 9 & 10
    GPIOA.AFR[1].modify(.{
        .@"AFR[1]" = 4,
        .@"AFR[2]" = 4,
    });
    // Re-enable peripheral
    I2C1.CR1.modify(.{ .PE = 1 });

    // Confirm our address
    const whoami = readAddrAccel(0x75);
    std.debug.assert(whoami == 0x11);
}

pub fn readAddrAccel(addr: u7) u8 {
    I2C1.CR2.modify(.{
        .SADD = ACCEL_ADDR,
        .NBYTES = 1,
        .DIR = .Write,
        .AUTOEND = .Software,
        .START = 1,
        .RELOAD = .Completed,
    });
    I2C1.TXDR.write(.{
        .TXDATA = addr,
        .padding = 0,
    });
    while (I2C1.ISR.read().TC == 0) {}
    I2C1.CR2.modify(.{
        .SADD = ACCEL_ADDR,
        .NBYTES = 1,
        .DIR = .Read,
        .AUTOEND = .Automatic,
        .START = 1,
        .RELOAD = .Completed,
    });
    while (I2C1.ISR.read().RXNE == 0) {}

    const data = I2C1.RXDR.read().RXDATA;

    return data;
}
