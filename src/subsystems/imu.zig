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
const DeltaTime = @import("deltaTime.zig");
const fp = @import("../util/fixedPoint.zig");

const AngleFpInt = fp.FixedPoint(16, 16, .signed);
const AccelFpInt = fp.FixedPoint(8, 24, .signed);
const AngleVec = fp.FpVector(AngleFpInt);
const AngleRotor = fp.FpRotor(AngleFpInt);
const AccelVec = fp.FpVector(AccelFpInt);

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

const ANGLE_LSB_TO_DPS = AngleFpInt.fromFloat((1.0 / 65.5) * std.math.pi / 180.0);
// const ACCEL_LSB_TO_MpS2 = AccelFpInt.fromFloatLit(9.81 / 16_384.0);
const ACCEL_LSB_TO_G = AccelFpInt.fromFloat(1.0 / 16_384.0);
const TEMP_LSB_TO_DegC = AccelFpInt.fromFloat(1.0 / 326.8);

// We are starting by representing orientation with euler angles
// They are applied in the order: yaw, pitch, roll
// The current angles are the ones required to get from facing "forward" in the world reference frame
//      to what is currently "forward" for our sensor
var orientation: AngleRotor = AngleRotor.identity();
var dt = DeltaTime.DeltaTime{};

// Higher = more correction from gravity
const alpha = AngleFpInt.fromFloat(0.3);

// Instantaneous values
var accel = AccelVec.zero();
var gyro = AngleVec.zero();
var temp = AccelFpInt.fromFloat(0.0);

/// Reads in new instantaneous values.
/// These can be accessed by getAccel() and getGyro()
/// Note that either this OR updateOrientation should be called, not both.
pub fn updateInstantaneousVals() void {

    // 6 2 byte vals
    // + temp (2 bytes)
    const BYTES_PER_READING = (6 * 2) + 2;

    var readingData: [BYTES_PER_READING]u8 = undefined;
    burstReadICM(0x3B, &readingData);

    accel.x = ACCEL_LSB_TO_G.mul(asI16(readingData[0..2]));
    accel.y = ACCEL_LSB_TO_G.mul(asI16(readingData[2..4]));
    accel.z = ACCEL_LSB_TO_G.mul(asI16(readingData[4..6]));
    temp = TEMP_LSB_TO_DegC.mul(asI16(readingData[6..8])).add(25);
    gyro.x = ANGLE_LSB_TO_DPS.mul(asI16(readingData[8..10]));
    gyro.y = ANGLE_LSB_TO_DPS.mul(asI16(readingData[10..12]));
    gyro.z = ANGLE_LSB_TO_DPS.mul(asI16(readingData[12..14]));
}

/// Updates both instantaneous values and orientation.
/// They can be accessed via getAccel(), getGyro(), and getOrientation()
/// This calls updateInstantaneousVals(), so do not call both
pub fn updateOrientation() void {
    updateInstantaneousVals();
    const milis = dt.milli();
    const sec = (AngleFpInt{ .fp = .{ .integer = @intCast(milis), .fraction = 0 } }).div(1000);

    // Quaternion derivative stuff
    // See: https://ahrs.readthedocs.io/en/latest/filters/angular.html#main-content
    // And: https://jacquesheunis.com/post/rotors/#how-do-i-turn-a-quaternion-into-an-equivalent-3d-rotor
    const deltaOrientation = (AngleRotor{
        .scalar = gyro.x.mul(-1).mul(orientation.yz).sub(gyro.y.mul(orientation.zx)).sub(gyro.z.mul(orientation.xy)),
        .yz = gyro.x.mul(orientation.scalar).add(gyro.z.mul(orientation.zx)).sub(gyro.y.mul(orientation.xy)),
        .zx = gyro.y.mul(orientation.scalar).sub(gyro.z.mul(orientation.yz)).add(gyro.x.mul(orientation.xy)),
        .xy = gyro.z.mul(orientation.scalar).add(gyro.y.mul(orientation.yz)).sub(gyro.x.mul(orientation.zx)),
    }).mul(sec.div(2));

    const predictedOrientation = orientation.add(deltaOrientation).norm();
    orientation = predictedOrientation;

    // Predicted gravity
    const predGrav = predictedOrientation.rotateVector(accel);

    var accelCorrection = if (predGrav.z.fp.integer < 0) unreachable // AngleRotor{
    else AngleRotor{
        .scalar = (predGrav.z.add(1).div(2).sqrt() catch unreachable).toFp(AngleFpInt),
        .yz = predGrav.y.div(predGrav.z.add(1).mul(2).sqrt() catch unreachable).toFp(AngleFpInt),
        .zx = predGrav.x.div(predGrav.z.add(1).mul(2).sqrt() catch unreachable).mul(-1).toFp(AngleFpInt),
        .xy = .{ .raw = 0 },
    };
    accelCorrection = accelCorrection.norm();
    accelCorrection = accelCorrection.slerpI(alpha);

    orientation = accelCorrection.mulRotor(predictedOrientation).norm();

    UartDebug.printIfDebug("Ornt: ", .{}) catch {};
    orientation.prettyPrint(UartDebug.writer, 5) catch {};
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
    // 500 dps max + no dlpf bypass
    const gyro_config: u8 = 0b01 << 3;
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

    // Turn of motherfucking sleep mode (hours spent)
    // Keep clock on best tho
    writeICM(0x6B, 1);
    // // Enable Fifo for accel and gyro
    // writeICM(0x23, 0b11 << 3);
    // // Enable global Fifo setting
    // writeICM(0x6a, 1 << 6);
    // Turn off output limiting
    writeICM(0x69, 1 << 1);

    dt.start();

    UartDebug.printIfDebug("ICM reset complete!\n", .{}) catch {};
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
