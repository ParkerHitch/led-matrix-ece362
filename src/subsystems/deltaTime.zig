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

pub const DeltaTime = struct {
    startTime: u32 = 0,
    currTime: u32 = 0,

    /// must be called before the .mili method to give a reference starting time
    pub fn start(self: *DeltaTime) void {
        self.currTime = @bitCast(TIM3.CNT);
    }

    /// returns the time in milliseconds since start or last milli call
    pub fn milli(self: *DeltaTime) u32 {
        self.startTime = self.currTime;
        self.currTime = @bitCast(TIM3.CNT);

        if (self.startTime < self.currTime) {
            return self.currTime - self.startTime;
        } else if (self.startTime > self.currTime) {
            return maxTimARR - self.startTime + self.currTime;
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
    dt.startTime = dt.currTime;
    dt.currTime = @bitCast(TIM3.CNT);

    if (dt.startTime < dt.currTime) {
        return dt.currTime - dt.startTime;
    } else if (dt.startTime > dt.currTime) {
        return maxTimARR - dt.startTime + dt.currTime;
    } else {
        // WARN: realllly scuffed
        cImport.nano_wait(3000000); // wait a couple milli seconds
        return dtMilli(dt); // to prevent updates from never happening if is dt updated to quickly
    }
}
