/// Uses TIM3 to capture delta time since last call
const microzig = @import("microzig");
const cImport = @import("../cImport.zig");
const cmsis = cImport.cmsis;
const peripherals = microzig.chip.peripherals;
const RCC = peripherals.RCC;
const TIM3 = peripherals.TIM3;
const maxTimARR: u32 = 0x0000ffff;
const clkPrescale: u32 = 48000 - 1;

pub fn init() void {
    // enable TIM3 clock source
    RCC.APB1ENR.modify(.{
        .TIM3EN = 1,
    });

    // prescale the clock the 1kHz so each count represents 1 milisecond
    TIM3.PSC = clkPrescale;
    // set arr to allow max count time between delta time calls
    TIM3.ARR = @bitCast(maxTimARR);

    TIM3.CR1.modify(.{
        .DIR = .Up, // upcounter
    });
}

pub fn start() void {
    // ensure timer is enabled & let a software update generation reset timer count without interupts or side effect
    TIM3.CR1.modify(.{
        .CEN = 1,
        .UDIS = 1,
    });

    // reset timer count
    TIM3.EGR.modify(.{
        .UG = 1,
    });

    // allow timer allow automatic counter reload
    TIM3.CR1.modify(.{
        .UDIS = 0,
    });
}

/// get time in mili seconds since start or previous mili()/seconds() call
pub fn mili() u32 {
    const timePause: u32 = 0;
    // pause timer
    TIM3.ARR = @bitCast(timePause);

    const deltaTime: u32 = @bitCast(TIM3.CNT);

    // let a software update generation reset timer count without interupts or side effect
    TIM3.CR1.modify(.{
        .UDIS = 1,
    });

    // reset timer count
    TIM3.EGR.modify(.{
        .UG = 1,
    });

    // allow timer allow automatic counter reload
    TIM3.CR1.modify(.{
        .UDIS = 0,
    });

    // resume timer
    TIM3.ARR = @bitCast(maxTimARR);

    return deltaTime;
}

/// get float time in seconds since start or previous mili()/seconds() call
pub fn seconds() f32 {
    return @as(f32, @floatFromInt(mili())) / 1000.0;
}
