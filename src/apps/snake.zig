const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const Random = std.Random;
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const joystick = @import("../subsystems/joystick.zig");
const buttonA = @import("../subsystems/button_a.zig");
const buttonB = @import("../subsystems/button_b.zig");
const UartDebug = @import("../util/uartDebug.zig");
const Vec3 = @import("../subsystems/vec3.zig").Vec3;

const maxSnakeSize = 16; // NOTE: win condition is to reach max snake size

pub const app: Application = .{
    .renderFn = &appMain,

    .name = "3D Snake",
    .authorfirst = "John",
    .authorlast = "Burns",
};

fn appMain() callconv(.C) void {
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    var prng = Random.DefaultPrng.init(@intCast(deltaTime.timestamp()));
    const rand = prng.random();

    var state: AppState = .{ .updatePeriod = 1000 / 2 };
    var snake: Snake = .{};
    snake.body[snake.headIdx] = randVec3(&rand);
    var pellot: Vec3 = newPellotPos(&rand, &snake);

    while (state.appRunning) {
        state.timeSinceUpdate += dt.milli();
        if (state.timeSinceUpdate < state.updatePeriod) {
            continue;
        }

        matrix.clearFrame(draw.Color(.BLACK));
        state.timeSinceUpdate = 0;

        // user input handling
        state.appRunning = !joystick.button_pressed();

        if (joystick.moved_up() and snake.headDir != .BACK) {
            snake.headDir = .FOWARD;
        }
        if (joystick.moved_down() and snake.headDir != .FOWARD) {
            snake.headDir = .BACK;
        }
        if (joystick.moved_right() and snake.headDir != .LEFT) {
            snake.headDir = .RIGHT;
        }
        if (joystick.moved_left() and snake.headDir != .RIGHT) {
            snake.headDir = .LEFT;
        }
        if (buttonA.pressed() and snake.headDir != .UP) {
            snake.headDir = .DOWN;
        }
        if (buttonB.pressed() and snake.headDir != .DOWN) {
            snake.headDir = .UP;
        }

        switch (state.gameState) {
            .PLAY => {
                // movement system
                snake.move();
                UartDebug.printIfDebug("Snake Head = <{}, {}, {}>\n", .{ snake.body[snake.headIdx].x, snake.body[snake.headIdx].y, snake.body[snake.headIdx].z }) catch {};

                // collision system
                if (snake.headOutOfBounds() or snake.bodyCollision(snake.body[snake.headIdx])) {
                    state.gameState = .LOSS;
                    continue; // fucking galaxy brain moment
                } else if (std.meta.eql(snake.body[snake.headIdx], pellot)) {
                    snake.grow();
                    pellot = newPellotPos(&rand, &snake);
                    if (snake.len >= maxSnakeSize) {
                        state.gameState = .WIN;
                        continue; // fucking galaxy brain moment
                    }
                }

                // draw to the display
                snake.drawSnake();
                matrix.setPixel(pellot.x, pellot.y, pellot.z, draw.Color(.RED));
            },
            .WIN => {
                matrix.clearFrame(draw.Color(.GREEN));
            },
            .LOSS => {
                matrix.clearFrame(draw.Color(.RED));
            },
        }

        matrix.render();
    }
}

const AppState = struct {
    updatePeriod: u32,
    timeSinceUpdate: u32 = 0,
    appRunning: bool = true,
    gameState: GameState = .PLAY,
};

const MoveDirection = enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
    FOWARD,
    BACK,
    NONE,
};

const GameState = enum {
    PLAY,
    WIN,
    LOSS,
};

const Snake = struct {
    body: [maxSnakeSize]Vec3 = [_]Vec3{.{}} ** maxSnakeSize,
    headIdx: u32 = 0,
    len: u32 = 1,
    headDir: MoveDirection = .NONE,

    fn move(self: *Snake) void {
        const prevHeadIdx = self.headIdx;
        self.headIdx = if (self.headIdx == 0) maxSnakeSize - 1 else self.headIdx - 1;
        self.body[self.headIdx] = self.body[prevHeadIdx];

        switch (self.headDir) {
            .UP => {
                self.body[self.headIdx].z += 1;
            },
            .DOWN => {
                self.body[self.headIdx].z -= 1;
            },
            .RIGHT => {
                self.body[self.headIdx].x += 1;
            },
            .LEFT => {
                self.body[self.headIdx].x -= 1;
            },
            .FOWARD => {
                self.body[self.headIdx].y += 1;
            },
            .BACK => {
                self.body[self.headIdx].y -= 1;
            },
            .NONE => {},
        }
    }

    fn grow(self: *Snake) void {
        self.len += 1;
    }

    fn headOutOfBounds(self: *Snake) bool {
        const headPos = self.body[self.headIdx];

        // WARN: AVERT YOUR EYES LESS THEY BE BLINDED!
        return headPos.x > matrix.upperBound or
            headPos.x < matrix.lowerBound or
            headPos.y > matrix.upperBound or
            headPos.y < matrix.lowerBound or
            headPos.z > matrix.upperBound or
            headPos.z < matrix.lowerBound;
    }

    /// NOTE: doesn't check for head collision
    fn bodyCollision(self: *Snake, pos: Vec3) bool {
        var isCollision: bool = false;
        var idx = (self.headIdx + 1) % maxSnakeSize;
        const end = (self.headIdx + self.len) % maxSnakeSize; // WARN: idx of the tail node after the tail

        while (idx != end) {
            if (std.meta.eql(self.body[idx], pos)) {
                isCollision = true;
                break;
            }
            idx = (idx + 1) % maxSnakeSize;
        }

        return isCollision;
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

/// randVec3 in range 0 to 7 for xyz
fn randVec3(rand: *const Random) Vec3 {
    return Vec3.init(
        rand.intRangeAtMost(i32, 0, 7),
        rand.intRangeAtMost(i32, 0, 7),
        rand.intRangeAtMost(i32, 0, 7),
    );
}

/// returns position within marix bounds that doesn't overlap with the snake
fn newPellotPos(rand: *const Random, snake: *Snake) Vec3 {
    var newPos: Vec3 = undefined;
    var isSpawnConflict = true;

    while (isSpawnConflict) {
        newPos = randVec3(rand);
        isSpawnConflict = snake.bodyCollision(newPos) or std.meta.eql(snake.body[snake.headIdx], newPos);
    }

    return newPos;
}
