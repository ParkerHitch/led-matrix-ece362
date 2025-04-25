const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const joystick = @import("../subsystems/joystick.zig");
const buttonA = @import("../subsystems/button_a.zig");
const buttonB = @import("../subsystems/button_b.zig");

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Cursor",
    .authorfirst = "John",
    .authorlast = "Burns",
};

const AppState = struct {
    updatePeriod: u32,
    timeSinceUpdate: u32 = 0,
    appRunning: bool = true,
};

const MoveDirection = enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
    FOWARD,
    BACK,
};

const Cursor = struct {
    x: i32 = 0,
    y: i32 = 0,
    z: i32 = 0,
    color: matrix.Led = .{ .r = 1, .g = 1, .b = 1 },

    fn move(self: *Cursor, dir: MoveDirection) bool {
        var hasMoved: bool = true;

        switch (dir) {
            .UP => {
                if (self.z < matrix.upperBound) {
                    self.z += 1;
                    return hasMoved;
                }
            },
            .DOWN => {
                if (self.z > matrix.lowerBound) {
                    self.z -= 1;
                    return hasMoved;
                }
            },
            .RIGHT => {
                if (self.x < matrix.upperBound) {
                    self.x += 1;
                    return hasMoved;
                }
            },
            .LEFT => {
                if (self.x > matrix.lowerBound) {
                    self.x -= 1;
                    return hasMoved;
                }
            },
            .FOWARD => {
                if (self.y < matrix.upperBound) {
                    self.y += 1;
                    return hasMoved;
                }
            },
            .BACK => {
                if (self.y > matrix.lowerBound) {
                    self.y -= 1;
                    return hasMoved;
                }
            },
        }

        hasMoved = false;
        return hasMoved;
    }

    fn draw(self: *Cursor) void {
        matrix.setPixel(self.x, self.y, self.z, self.color);
    }
};

fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    var state: AppState = .{
        .updatePeriod = 1000 / 30,
    };
    var cursor: Cursor = .{};

    while (state.appRunning) {
        state.timeSinceUpdate += dt.milli();
        if (state.timeSinceUpdate < state.updatePeriod) {
            continue;
        }

        joystick.joystick_update();
        state.timeSinceUpdate = 0;
        state.appRunning = !joystick.button_pressed();

        // cursor logic
        cursor.color = draw.Color(.WHITE); // reset color
        if (joystick.moved_up()) {
            if (!cursor.move(.FOWARD)) {
                cursor.color = draw.Color(.RED);
            }
        } else if (joystick.moved_down()) {
            if (!cursor.move(.BACK)) {
                cursor.color = draw.Color(.RED);
            }
        } else if (joystick.moved_left()) {
            if (!cursor.move(.LEFT)) {
                cursor.color = draw.Color(.RED);
            }
        } else if (joystick.moved_right()) {
            if (!cursor.move(.RIGHT)) {
                cursor.color = draw.Color(.RED);
            }
        } else if (buttonA.pressed()) {
            if (!cursor.move(.DOWN)) {
                cursor.color = draw.Color(.RED);
            }
        } else if (buttonB.pressed()) {
            if (!cursor.move(.UP)) {
                cursor.color = draw.Color(.RED);
            }
        }

        // draw to the display
        matrix.clearFrame(draw.Color(.BLACK));

        cursor.draw();

        matrix.render();
    }
}
