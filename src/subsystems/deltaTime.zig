/// deltaTime.zig
/// Uses TIM3 to capture delta time since last call
const microzig = @import("microzig");
const cImport = @import("../cImport.zig");
const cmsis = cImport.cmsis;
const peripherals = microzig.chip.peripherals;
const RCC = peripherals.RCC;
const TIM3 = peripherals.TIM3;
const maxTimARR: u32 = 0x0000ffff;
const clkPrescale: u32 = 48000 - 1;

/// set's up TIM3 as internal timer
/// should only be called once in program's execution
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

    TIM3.CR1.modify(.{
        .CEN = 1,
    });
}

/// get the dt sources timestamp in miliseconds from the time init() is called
/// WARN: this timestamp resets to 0 every ~65.5 seconds,
/// so do not use for long term time measurnments. Best used for a random seed.
pub fn timestamp() callconv(.C) u32 {
    return @bitCast(TIM3.CNT);
}

pub const DeltaTime = struct {
    currTime: u32 = 0,

    /// must be called before the .mili method to give a reference starting time
    pub fn start(self: *DeltaTime) void {
        self.currTime = @bitCast(TIM3.CNT);
    }

    /// returns the time in milliseconds since start or last milli call
    pub fn milli(self: *DeltaTime) u32 {
        const startTime = self.currTime;
        self.currTime = @bitCast(TIM3.CNT);

        if (startTime < self.currTime) {
            return self.currTime - startTime;
        } else if (startTime > self.currTime) {
            return maxTimARR - startTime + self.currTime;
        } else {
            // WARN: realllly scuffed
            cImport.nano_wait(3000000); // wait a couple milli seconds
            return self.milli(); // to prevent updates from never happening if is dt updated to quickly
        }
    }
};

//---------------//
//---C-Support---//
//---------------//

pub export fn dtStart(dt: *cImport.DeltaTime) callconv(.C) void {
    dt.currTime = @bitCast(TIM3.CNT);
}

/// get time in mili seconds since start or previous mili()/seconds() call
pub export fn dtMilli(dt: *cImport.DeltaTime) callconv(.C) c_uint {
    const startTime = dt.currTime;
    dt.currTime = @bitCast(TIM3.CNT);

    if (startTime < dt.currTime) {
        return dt.currTime - startTime;
    } else if (startTime > dt.currTime) {
        return maxTimARR - startTime + dt.currTime;
    } else {
        // WARN: realllly scuffed
        cImport.nano_wait(3000000); // wait a couple milli seconds
        return dtMilli(dt); // to prevent updates from never happening if is dt updated to quickly
    }
}
