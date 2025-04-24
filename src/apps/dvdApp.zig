const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const Vec3f = @import("../subsystems/vec3.zig").Vec3f;

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "DVD Logo Screen",
    .authorfirst = "John",
    .authorlast = "Burns",
};

// time keeping vairiables to limit tickRate
const tickRate: u32 = 60; // i.e. target fps or update rate
const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
var timeSinceUpdate: u32 = 0;

// app entry point
fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // collision consts
    const matrixLowerBound: f32 = 0;
    const matrixUpperBound: f32 = 7;

    var dvd = draw.Box.initCube(Vec3f.init(0, 0, 0), 4, draw.Color(.WHITE));
    var dvdVel = Vec3f.init(0.16, 0.08, 0.1);
    // var dvdVel = Vec3f.init() // units per millsecond
    // var dvd = draw.Box.initBox(Vec3.init(0, 0, 0), 3, 2, 1, draw.Color(.WHITE));

    while (true) {
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            //updateMovement(&dvd, &dvdVel);
            dvd.pos = dvd.pos.add(&dvdVel);
            if (dvd.pos.x + @as(f32, @floatFromInt(dvd.width)) - 1 > matrixUpperBound) {
                dvd.pos.x = matrixUpperBound - @as(f32, @floatFromInt(dvd.width)) + 1;
                dvdVel.x = dvdVel.x * -1.0;
            }
            if (dvd.pos.x < matrixLowerBound) {
                dvd.pos.x = matrixLowerBound;
                dvdVel.x = dvdVel.x * -1.0;
            }
            if (dvd.pos.y + @as(f32, @floatFromInt(dvd.length)) - 1 > matrixUpperBound) {
                dvd.pos.y = matrixUpperBound - @as(f32, @floatFromInt(dvd.length)) + 1;
                dvdVel.y = dvdVel.y * -1.0;
            }
            if (dvd.pos.y < matrixLowerBound) {
                dvd.pos.y = matrixLowerBound;
                dvdVel.y = dvdVel.y * -1.0;
            }
            if (dvd.pos.z + @as(f32, @floatFromInt(dvd.height)) - 1 > matrixUpperBound) {
                dvd.pos.z = matrixUpperBound - @as(f32, @floatFromInt(dvd.height)) + 1;
                dvdVel.z = dvdVel.z * -1.0;
            }
            if (dvd.pos.z < matrixLowerBound) {
                dvd.pos.z = matrixLowerBound;
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
