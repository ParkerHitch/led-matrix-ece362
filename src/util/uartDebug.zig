/// uartDebug.zig
/// A transmit-only uart thing to help with debugging.
/// Super inneficient and bad, but nice to have when testing.
/// Nothing in here can be used in release builds. It will compile error if you try.
const buildMode = @import("builtin").mode;
const microzig = @import("microzig");
const RCC = microzig.chip.peripherals.RCC;
const USART5 = microzig.chip.peripherals.USART5;
const GPIOC = microzig.chip.peripherals.GPIOC;
const GPIOD = microzig.chip.peripherals.GPIOD;
const std = @import("std");
const UartWriter = std.io.Writer(void, UartWriteError, write);

pub const UartWriteError = error{TimeoutError};
pub const writer = UartWriter{ .context = undefined };

pub fn init() void {
    if (buildMode != .Debug) {
        @compileError("The uart debug is only for debug builds. Do not use it in release modes. Check via \"@import(\"builtin\").mode.\"");
    }

    RCC.AHBENR.modify(.{
        .GPIOCEN = 1,
        .GPIODEN = 1,
    });

    // C12 AF
    GPIOC.MODER.modify(.{ .@"MODER[12]" = .Alternate });

    // D2 AF
    GPIOD.MODER.modify(.{ .@"MODER[2]" = .Alternate });
    // C12 to AF2
    GPIOC.AFR[1].modify(.{ .@"AFR[4]" = 2 });

    // D2 to AF2
    GPIOD.AFR[0].modify(.{ .@"AFR[2]" = 2 });

    // Usart5 clock
    RCC.APB1ENR.modify(.{ .USART5EN = 1 });

    // Disable USART5
    USART5.CR1.modify(.{ .UE = 0 });
    // Set size of 8 bits
    // 16x oversampling and no parity control
    USART5.CR1.modify(.{
        .M1 = .M0,
        .M0 = .Bit8,
        .PCE = 0,
        .OVER8 = .Oversampling16,
        .RE = 0, // We don't really use this as of yet but maybe one day
        .TE = 1,
    });
    // One stop bit
    USART5.CR2.modify(.{ .STOP = .Stop1 });

    // 48 MHz / 0x1A1 = 115.2 KHz
    // Set to 115.2 KBps
    USART5.BRR.modify(.{ .BRR = 0x1A1 });

    // Enable transmitter, reciever, and module
    USART5.CR1.modify(.{ .UE = 1 });

    writer.print("UART initialized!\n", .{}) catch {};
}

/// Prints if we are in a debug build. Does nothing otherwise.
/// Hopefully will get optimized out in release modes but idk. Need to test that
pub fn printIfDebug(comptime format: []const u8, args: anytype) UartWriteError!void {
    if (buildMode == .Debug) {
        try writer.print(format, args);
    } else {
        return;
    }
}

fn write(_: void, bytes: []const u8) UartWriteError!usize {
    if (buildMode != .Debug) {
        @compileError("Uart is only for debug builds. Do not call print in release builds. Check via \"@import(\"builtin\").mode.\"");
    }
    var written: usize = 0;
    for (bytes) |byte| {
        try putchar(byte);
        written += 1;
    }
    return written;
}

// 2s timeout
const timeout: comptime_int = 48_000_000 * 2;

fn putchar(c: u8) UartWriteError!void {
    if (c == '\n') {
        try putchar('\r');
    }
    var elapsed: usize = 0;
    while (USART5.ISR.read().TXE == 0) {
        elapsed += 1;
        if (elapsed == timeout) {
            return UartWriteError.TimeoutError;
        }
    }
    USART5.TDR.write(.{ .DR = c, .padding = 0 });
}
