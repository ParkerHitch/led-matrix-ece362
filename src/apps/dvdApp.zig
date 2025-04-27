const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const Vec3f = @import("../subsystems/vec3.zig").Vec3f;
const joystick = @import("../subsystems/joystick.zig");

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "DVD Logo Screen",
    .authorfirst = "John",
    .authorlast = "Burns",
};

// time keeping vairiables to limit tickRate
const tickRate: u32 = 15; // i.e. target fps or update rate
const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
var timeSinceUpdate: u32 = 0;

// app entry point
fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    var dvd = draw.Box.initCube(Vec3f.init(0, 0, 0), 3, draw.Color(.WHITE));
    var dvdVel = Vec3f.init(0.16, 0.08, 0.1);

    var appRunning: bool = true;

    while (appRunning) {
        joystick.joystick_update();
        appRunning = !joystick.button_pressed();

        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            //updateMovement(&dvd, &dvdVel);
            dvd.pos = dvd.pos.add(&dvdVel);
            if (dvd.pos.x + @as(f32, @floatFromInt(dvd.width)) - 1 > matrix.upperBound) {
                dvd.pos.x = matrix.upperBound - @as(f32, @floatFromInt(dvd.width)) + 1;
                dvdVel.x = dvdVel.x * -1.0;
            }
            if (dvd.pos.x < matrix.lowerBound) {
                dvd.pos.x = matrix.lowerBound;
                dvdVel.x = dvdVel.x * -1.0;
            }
            if (dvd.pos.y + @as(f32, @floatFromInt(dvd.length)) - 1 > matrix.upperBound) {
                dvd.pos.y = matrix.upperBound - @as(f32, @floatFromInt(dvd.length)) + 1;
                dvdVel.y = dvdVel.y * -1.0;
            }
            if (dvd.pos.y < matrix.lowerBound) {
                dvd.pos.y = matrix.lowerBound;
                dvdVel.y = dvdVel.y * -1.0;
            }
            if (dvd.pos.z + @as(f32, @floatFromInt(dvd.height)) - 1 > matrix.upperBound) {
                dvd.pos.z = matrix.upperBound - @as(f32, @floatFromInt(dvd.height)) + 1;
                dvdVel.z = dvdVel.z * -1.0;
            }
            if (dvd.pos.z < matrix.lowerBound) {
                dvd.pos.z = matrix.lowerBound;
                dvdVel.z = dvdVel.z * -1.0;
            }

            // draw to the display
            matrix.clearFrame(draw.Color(.BLACK));

            dvd.draw();

            matrix.render();
            timeSinceUpdate = 0;
        }
    }
}

fn updateMovement(box: *draw.Box, vel: *Vec3f) void {
    vel.* = vel.mult(@as(f32, @floatFromInt(timeSinceUpdate)) / 1000.0);
    box.pos = box.pos.add(vel);
}
