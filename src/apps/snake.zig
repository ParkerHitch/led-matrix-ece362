const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const rand = std.Random;
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const joystick = @import("../subsystems/joystick.zig");
const buttonA = @import("../subsystems/button_a.zig");
const buttonB = @import("../subsystems/button_b.zig");
const Vec3 = @import("../subsystems/vec3.zig").Vec3;

const maxSnakeSize = 256;

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

const GameState = enum {
    WIN,
    LOSS,
    PLAY,
};

const Snake = struct {
    body: [maxSnakeSize]Vec3 = [_]Vec3{.{}} ** maxSnakeSize,
    headIdx: u32 = 0,
    len: u32 = 1,
    headDir: MoveDirection = .FOWARD,

    fn move(self: *Snake) void {
        const prevHeadIdx = self.headIdx;
        self.headIdx = if (self.headIdx == 0) maxSnakeSize else self.headIdx - 1;

        switch (self.headDir) {
            .UP => {
                self.body[self.headIdx].z = self.body[prevHeadIdx].z + 1;
            },
            .DOWN => {
                self.body[self.headIdx].z = self.body[prevHeadIdx].z - 1;
            },
            .RIGHT => {
                self.body[self.headIdx].x = self.body[prevHeadIdx].x + 1;
            },
            .LEFT => {
                self.body[self.headIdx].x = self.body[prevHeadIdx].x - 1;
            },
            .FOWARD => {
                self.body[self.headIdx].y = self.body[prevHeadIdx].y + 1;
            },
            .BACK => {
                self.body[self.headIdx].y = self.body[prevHeadIdx].y - 1;
            },
        }
    }

    fn grow(self: *Snake) void {
        self.len += 1;
    }

    fn drawSnake(self: *Snake) void {
        var idx = self.headIdx;
        const end = (self.headIdx + self.len) % maxSnakeSize; // WARN: not the idx of the tail

        while (idx != end) {
            const currNode = self.body[idx];
            matrix.setPixel(currNode.x, currNode.y, currNode.z, draw.Color(.GREEN));
            idx = (idx + 1) % maxSnakeSize;
        }
    }
};

fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    var state: AppState = .{
        .updatePeriod = 1000 / 30,
    };
    var snake: Snake = .{};

    while (state.appRunning) {
        state.timeSinceUpdate += dt.milli();
        if (state.timeSinceUpdate < state.updatePeriod) {
            continue;
        }

        joystick.joystick_update();
        state.timeSinceUpdate = 0;
        state.appRunning = !joystick.button_pressed();

        // user input handling
        if (joystick.moved_up()) {
            snake.headDir = .FOWARD;
        } else if (joystick.moved_down()) {
            snake.headDir = .BACK;
        } else if (joystick.moved_right()) {
            snake.headDir = .RIGHT;
        } else if (joystick.moved_left()) {
            snake.headDir = .LEFT;
        } else if (buttonA.pressed()) {
            snake.headDir = .DOWN;
        } else if (buttonB.pressed()) {
            snake.headDir = .UP;
        }

        // movment update
        snake.move();

        // collision detection

        // draw to the display
        matrix.clearFrame(draw.Color(.BLACK));

        snake.drawSnake();

        matrix.render();
    }
}
