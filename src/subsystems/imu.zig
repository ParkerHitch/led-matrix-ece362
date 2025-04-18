const std = @import("std");
const microzig = @import("microzig");
const cmsis = @import("../cImport.zig").cmsis;
const c = @import("../cImport.zig");
const peripherals = microzig.chip.peripherals;
const periph_types = microzig.chip.types.peripherals;
const I2C1 = peripherals.I2C1;
const GPIOA = peripherals.GPIOA;
const RCC = peripherals.RCC;
const UartDebug = @import("../util/uartDebug.zig");

// Sample rate for the IMU in Hz.
// 1k should be divisible by this number
const SAMPLE_RATE = 10;
const ICM_ADDR = 0x69;
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
    const whoami = readICM(0x75);
    std.debug.assert(whoami == 0x11);

    resetICM();

    while (true) {
        c.nano_wait(200_000_000);
        UartDebug.printIfDebug("0x6B: {}\n", .{readICM(0x6B)}) catch {};
        UartDebug.printIfDebug("Fifo count: {}\n", .{readI16(0x72)}) catch {};
        UartDebug.printIfDebug("Accel z:    {}\n", .{readI16(0x3F)}) catch {};
        UartDebug.printIfDebug("Temp: {}\n", .{readI16(0x41)}) catch {};
        UartDebug.printIfDebug("Gyro z: {}\n", .{readI16(0x47)}) catch {};
        // _ = fifoCnt;
    }
}

fn readI16(startAddr: u8) i16 {
    var data: [2]u8 = undefined;
    burstReadICM(startAddr, &data);
    const rawData: u16 = (@as(u16, data[0]) << 8) + data[1];
    return @bitCast(rawData);
}

// Resets and configures our desired settings
pub fn resetICM() void {
    // Reset
    writeICM(0x6B, 1 << 7);

    // Wait for reset bit to clear
    // 2 ms startup time
    c.nano_wait(2_000_000);
    while ((readICM(0x6B) & (1 << 7)) > 0) {}

    // Burst write our config
    const smplrt_div: u8 = 99;
    // FIFO on overwrite, DLPF set to 5 hz
    const config: u8 = (1 << 6) | (6);
    // defaults. Minimum full scale + no dlpf bypass
    const gyro_config: u8 = 0;
    // defaults. Minimum full scale
    const accel_config: u8 = 0;
    // LPF to 5.1 Hz, start with averaging just 4
    const accel_config2: u8 = 6;
    // no low power for gyro
    const gyro_lp_cfg: u8 = 0x00;
    burstWriteICM(0x19, &.{
        smplrt_div,
        config,
        gyro_config,
        accel_config,
        accel_config2,
        gyro_lp_cfg,
    });

    UartDebug.printIfDebug("0x19: {}\n", .{readICM(0x19)}) catch {};
    UartDebug.printIfDebug("0x1A: {}\n", .{readICM(0x1A)}) catch {};
    UartDebug.printIfDebug("0x1B: {}\n", .{readICM(0x1B)}) catch {};
    UartDebug.printIfDebug("0x1C: {}\n", .{readICM(0x1C)}) catch {};
    UartDebug.printIfDebug("0x1D: {}\n", .{readICM(0x1D)}) catch {};
    UartDebug.printIfDebug("0x1E: {}\n", .{readICM(0x1E)}) catch {};

    // Turn of motherfucking sleep mode (hours spent)
    // Keep clock on best tho
    writeICM(0x6B, 1);
    // Enable Fifo for accel and gyro
    writeICM(0x23, 0b11 << 3);
    // Enable global Fifo setting
    writeICM(0x6a, 1 << 6);
    // Turn off output limiting
    writeICM(0x69, 1 << 1);
}

pub fn readICM(addr: u8) u8 {
    I2C1.CR2.modify(.{
        .SADD = ICM_ADDR << 1,
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
        .SADD = ICM_ADDR << 1,
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

pub fn burstReadICM(addr: u8, dest: []u8) void {
    I2C1.CR2.modify(.{
        .SADD = ICM_ADDR << 1,
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
        .SADD = ICM_ADDR << 1,
        .NBYTES = @as(u8, @intCast(dest.len)),
        .DIR = .Read,
        .AUTOEND = .Automatic,
        .START = 1,
        .RELOAD = .Completed,
    });
    for (0..dest.len) |i| {
        while (I2C1.ISR.read().RXNE == 0) {}
        dest[i] = I2C1.RXDR.read().RXDATA;
    }
}

pub fn writeICM(addr: u8, data: u8) void {
    I2C1.CR2.modify(.{
        .SADD = ICM_ADDR << 1,
        .NBYTES = 2,
        .DIR = .Write,
        .AUTOEND = .Automatic,
        .START = 1,
        .RELOAD = .Completed,
    });
    I2C1.TXDR.write(.{
        .TXDATA = addr,
        .padding = 0,
    });
    while (I2C1.ISR.read().TXE == 0) {}
    I2C1.TXDR.write(.{
        .TXDATA = data,
        .padding = 0,
    });
    while (I2C1.ISR.read().BUSY == 1) {}
}
/// NOTE:
/// Don't you dare burst write a slice with length > 254
pub fn burstWriteICM(startAddr: u8, data: []const u8) void {
    I2C1.CR2.modify(.{
        .SADD = ICM_ADDR << 1,
        .NBYTES = 1 + @as(u8, @intCast(data.len)),
        .DIR = .Write,
        .AUTOEND = .Automatic,
        .START = 1,
        .RELOAD = .Completed,
    });
    I2C1.TXDR.write(.{
        .TXDATA = startAddr,
        .padding = 0,
    });
    for (data) |byte| {
        while (I2C1.ISR.read().TXE == 0) {}
        I2C1.TXDR.write(.{
            .TXDATA = byte,
            .padding = 0,
        });
    }
    while (I2C1.ISR.read().BUSY == 1) {}
}

// pub const AccelRegister = struct {
//     address: u8,
//     layout: type,
//
//     pub const CONFIG = AccelRegister{
//         .address = 0x1A,
//         .layout = packed struct {
//             DLPF_CFG: u3,
//             EXT_SYNC_SET: u3,
//             FIFO_MODE: u1,
//             padding: u1 = 0,
//         },
//     };
//
//     pub const GYRO_CONFIG = AccelRegister{
//         .address = 0x1A,
//         .layout = packed struct {
//             DLPF_CFG: u3,
//             FS_SEL: u2,
//             reserved: u1,
//             FCHOICE_B: u2,
//         },
//     };
// };
