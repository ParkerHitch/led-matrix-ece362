const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const joystick = @import("../subsystems/joystick.zig");

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Gamecube",
    .authorfirst = "Micah",
    .authorlast = "Samuel",
};

// app entry point
fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // time keeping vairiables to limit tickRate
    const tickRate: u32 = 8; // i.e. target fps or update rate
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // loop control variable
    var appRunning = true;

    // variable for keeping track the color to draw
    var state: i32 = 0;
    var velx: i32 = 0;
    var vely: i32 = 2;
    var velz: i32 = 0;
    var curx: i32 = 6;
    var cury: i32 = 4;
    var curz: i32 = 7;
    var prevx: i32 = 0;
    var prevy: i32 = 0;
    var prevz: i32 = 0;
    var length: i32 = 2;
    var width: i32 = 2;
    var height: i32 = 1;
    var prevLength: i32 = 0;
    var prevWidth: i32 = 0;
    var prevHeight: i32 = 0;
    var drawIdx: u3 = 4;
    var prevDrawIdx: u3 = 7;

    // clear to get rid of previous animation
    matrix.clearFrame(draw.Color(.BLACK));

    // TODO: replace true in while true with joystick press exit condition
    while (appRunning) {
        appRunning = !joystick.button_pressed();

        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0;

            // draw states
            draw.box(prevx, prevy, prevz, prevWidth, prevLength, prevHeight, draw.Color(@enumFromInt(prevDrawIdx)));
            draw.box(curx, cury, curz, width, length, height, draw.Color(@enumFromInt(drawIdx)));

            prevDrawIdx = drawIdx;
            prevx = curx;
            prevy = cury;
            prevz = curz;
            prevHeight = height;
            prevLength = length;
            prevWidth = width;

            // velocity update states
            if (state == 1) {
                vely = 0;
                velx = -2;
            } else if (state == 4) {
                velx = 0;
                velz = -2;
                height = 2;
                width = 1;
                curz = 8;
                // curx = 0;
            } else if (state == 8) {
                velz = 0;
                vely = -2;
                curx = 0;
            } else if (state == 11) {
                vely = 0;
                velx = 2;
                width = 2;
                length = 1;
                curx = -2;
            } else if (state == 15) {
                velx = 0;
                velz = 2;
            } else if (state == 18) {
                velz = 0;
                velx = -2;
            } else if (state == 19) {
                velx = 0;
                velz = -2;
                curz = 8;
                curx = 0;
                cury = 0;
                width = 4;
                length = 4;
                height = 2;
            }

            state = if (state == 21) 0 else state + 1;
            curx = curx + velx;
            cury = cury + vely;
            curz = curz + velz;

            if (state == 0) {
                drawIdx = if (drawIdx == 4) 7 else 4;
                velx = 0;
                vely = 2;
                velz = 0;
                curx = 6;
                cury = 4;
                curz = 7;
                length = 2;
                width = 2;
                height = 1;
            }

            matrix.render();
        }
    }
}
