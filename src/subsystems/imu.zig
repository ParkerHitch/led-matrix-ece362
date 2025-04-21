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
const fp = @import("../util/fixedPoint.zig");

const AngleFpInt = fp.FixedPoint(16, 16, .signed);
const AccelFpInt = fp.FixedPoint(8, 24, .signed);

// Sample rate for the IMU in Hz.
// 1k should be divisible by this number
const SAMPLE_RATE = 200;
comptime {
    if (@mod(1000, SAMPLE_RATE) != 0) {
        @compileError("In imu.zig, please use a SAMPLE_RATE that evenly divides 1000");
    }
}
const ICM_ADDR = 0x69;
const MAG_ADDR = 0x0c;

const ANGLE_LSB_TO_DPS = AngleFpInt.fromFloatLit(1.0 / 131.0);
const ACCEL_LSB_TO_MpS2 = AccelFpInt.fromFloatLit(9.81 / 16_384.0);
const TEMP_LSB_TO_DegC = AngleFpInt.fromFloatLit(1.0 / 326.8);

// We are starting by representing orientation with euler angles
// They are applied in the order: yaw, pitch, roll
// The current angles are the ones required to get from facing "forward" in the world reference frame
//      to what is currently "forward" for our sensor
var yaw = AngleFpInt.fromFloatLit(0);
var pitch = AngleFpInt.fromFloatLit(0);
var roll = AngleFpInt.fromFloatLit(0);

// TODO:
// Can we make this malloc? Yes.
var fifoBuffer = [_]u8{0} ** 1008;

pub fn update() void {

    // 6 2 byte vals
    // + temp
    const BYTES_PER_READING = 8 * 2;

    const num_bytes = readU16(0x72);
    _ = num_bytes;
    // UartDebug.printIfDebug("{} bytes in fifo\n", .{num_bytes}) catch {};
    // const num_readings = num_bytes / BYTES_PER_READING;
    const num_readings: i32 = 1;
    if (num_readings == 0)
        return;

    var rawBurst: []u8 = fifoBuffer[0..(BYTES_PER_READING * num_readings)];
    // burstReadICM(0x74, rawBurst);
    burstReadICM(0x3B, rawBurst);

    var a_x_sum = AccelFpInt{ .raw = 0 };
    var a_y_sum = AccelFpInt{ .raw = 0 };
    var a_z_sum = AccelFpInt{ .raw = 0 };
    var temp_sum = AngleFpInt{ .raw = 0 };
    var g_x_sum = AngleFpInt{ .raw = 0 };
    var g_y_sum = AngleFpInt{ .raw = 0 };
    var g_z_sum = AngleFpInt{ .raw = 0 };

    for (0..num_readings) |i| {
        const readingData = rawBurst[BYTES_PER_READING * i ..][0..BYTES_PER_READING];

        const a_x = ACCEL_LSB_TO_MpS2.mulRaw(asI16(readingData[0..2]));
        const a_y = ACCEL_LSB_TO_MpS2.mulRaw(asI16(readingData[2..4]));
        const a_z = ACCEL_LSB_TO_MpS2.mulRaw(asI16(readingData[4..6]));
        var temp = TEMP_LSB_TO_DegC.mulRaw(asI16(readingData[6..8]));
        temp.fp.integer += 25;
        const g_x = ANGLE_LSB_TO_DPS.mulRaw(asI16(readingData[8..10]));
        const g_y = ANGLE_LSB_TO_DPS.mulRaw(asI16(readingData[10..12]));
        const g_z = ANGLE_LSB_TO_DPS.mulRaw(asI16(readingData[13..15]));

        a_x_sum = a_x_sum.add(a_x);
        a_y_sum = a_y_sum.add(a_y);
        a_z_sum = a_z_sum.add(a_z);
        temp_sum = temp_sum.add(temp);
        g_x_sum = g_x_sum.add(g_x);
        g_y_sum = g_y_sum.add(g_y);
        g_z_sum = g_z_sum.add(g_z);

        // UartDebug.printIfDebug("Data {}:\n", .{i}) catch {};
        // UartDebug.printIfDebug("  a_x: {}\n  a_y: {}\n  a_z: {}\n", .{ a_x.fp.integer, a_y.fp.integer, a_z.fp.integer }) catch {};
        // UartDebug.printIfDebug("  g_x: {}\n  g_y: {}\n  g_z: {}\n", .{ g_x.fp.integer, g_y.fp.integer, g_z.fp.integer }) catch {};
    }
    const a_x = a_x_sum.divRaw(num_readings);
    const a_y = a_y_sum.divRaw(num_readings);
    const a_z = a_z_sum.divRaw(num_readings);
    const temp = temp_sum.divRaw(num_readings);
    const g_x = g_x_sum.divRaw(num_readings);
    const g_y = g_y_sum.divRaw(num_readings);
    const g_z = g_z_sum.divRaw(num_readings);
    UartDebug.printIfDebug("a_x:{: >3}  a_y:{: >3}  a_z:{: >3} t:{: >3} g_x:{: >3}  g_y:{: >3}  g_z:{: >3}\n", .{ a_x.fp.integer, a_y.fp.integer, a_z.fp.integer, temp.fp.integer, g_x.fp.integer, g_y.fp.integer, g_z.fp.integer }) catch {};
}

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
}

fn asI16(data: *[2]u8) i16 {
    return @bitCast((@as(u16, data[0]) << 8) + data[1]);
}

fn readI16(startAddr: u8) i16 {
    var data: [2]u8 = undefined;
    burstReadICM(startAddr, &data);
    const rawData: u16 = (@as(u16, data[0]) << 8) + data[1];
    return @bitCast(rawData);
}

fn readU16(startAddr: u8) u16 {
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
    const smplrt_div: u8 = (1000 / SAMPLE_RATE) - 1;
    // DLPF set to 5 hz
    const config: u8 = 6;
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
    // // Also turn off temp
    // writeICM(0x6B, 1 | (1 << 3));
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
    if (dest.len == 0) {
        return;
    }
    I2C1.CR2.modify(.{
        .SADD = ICM_ADDR << 1,
        .NBYTES = 1,
        .DIR = .Write,
        .AUTOEND = .Software,
        .START = 1,
        .RELOAD = .Completed,
    });
    // while (I2C1.ISR.read().TXIS == 0) {
    //     if (I2C1.ISR.read().NACKF == 1) {
    //         UartDebug.printIfDebug("Nack!!!\n", .{}) catch {};
    //         @panic("Nack recieved");
    //     }
    // }
    I2C1.TXDR.write(.{
        .TXDATA = addr,
        .padding = 0,
    });
    while (I2C1.ISR.read().TC == 0) {}
    var toRead: usize = dest.len;
    var i: usize = 0;
    var toStart = true;
    while (toRead > 255) {
        toRead -= 255;
        I2C1.CR2.modify(.{
            .SADD = ICM_ADDR << 1,
            .NBYTES = 255,
            .DIR = .Read,
            .AUTOEND = .Software,
            .START = @as(u1, if (toStart) 1 else 0),
            .RELOAD = .NotCompleted,
        });
        toStart = false;
        const iEnd = i + 255;
        while (i < iEnd) {
            while (I2C1.ISR.read().RXNE == 0) {}
            dest[i] = I2C1.RXDR.read().RXDATA;
            i += 1;
        }
        while (I2C1.ISR.read().TCR == 0) {}
    }
    I2C1.CR2.modify(.{
        .SADD = ICM_ADDR << 1,
        .NBYTES = @as(u8, @intCast(toRead)),
        .DIR = .Read,
        .AUTOEND = .Automatic,
        .START = @as(u1, if (toStart) 1 else 0),
        .RELOAD = .Completed,
    });
    while (i < dest.len) {
        while (I2C1.ISR.read().RXNE == 0) {}
        dest[i] = I2C1.RXDR.read().RXDATA;
        i += 1;
    }
    // while (I2C1.ISR.read().TC == 0) {}
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
