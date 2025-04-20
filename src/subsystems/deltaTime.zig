const time = @import("std").time;

var prevTime: i64 = 0;
var currTime: i64 = 0;

pub fn start() void {
    currTime = time.milliTimestamp();
}

// returns the delta Time in seconds
pub fn get() f32 {
    prevTime = currTime;
    currTime = time.milliTimestamp();
    const deltaTime: f32 = @as(f32, @floatFromInt(currTime - prevTime)) / 1000.0;
    return deltaTime;
}
