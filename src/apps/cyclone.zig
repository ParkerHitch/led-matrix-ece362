/// To make your own app simply copy this file and edit it as you see fit.
/// keep in mind to read all warnings and notes.
/// WARN: c headers and zig header do not have the process,
/// so read the language specific template file
const Application = @import("../cImport.zig").Application;
const std = @import("std");
const deltaTime = @import("../subsystems/deltaTime.zig");
const matrix = @import("../subsystems/matrix.zig");
const draw = @import("../subsystems/draw.zig");
const joystick = @import("../subsystems/joystick.zig");
const button = @import("../subsystems/button_a.zig");
const restart = @import("../subsystems/button_b.zig");
// const rand = std.Random; // <-- uncomment for random lib
//
// const test = rand.DefaultPrng;

// NOTE: matrix.setPixel and matrix.clearFrame are the only 2
// basic matrix pixel set functions. All future drawing abstractions
// should be placed outside the matrix.zig file, and use setPixel and or clearFrame

// NOTE: helper functions are allowed but should not be pub functions to keep file scope

// WARN: required struct header must be named app,
// .renderFn must be a pointer to your app's entry point,
// you MUST add &@import("<your file name>.zig").app to the zigApps in index.zig,
// and your file name must not be the same as any other app
pub const app: Application = .{
    .renderFn = &appMain,

    .name = "Cyclone (Multi)",
    .authorfirst = "Richard",
    .authorlast = "Ye",
};

const Cyclone = struct {
    // state of game 1-4
    state: i32 = 1,

    // x and y stats for moving light
    x: i32 = 4,
    xVel: i32 = 1,
    y: i32 = 0,
    yVel: i32 = 0,

    // shows click for a second
    showing_placement: bool = false,

    pub fn getspeed(self: Cyclone) i32 {
        return 5 - self.state;
    }
};

fn loadInnerRing(game: Cyclone) void {
    for (1..7) |x| {
        matrix.setPixel(@intCast(x), 6, 0, draw.Color(.RED));
        if (game.state == 1) {
            if (x >= 2 and x <= 5) {
                matrix.setPixel(@intCast(x), 1, 0, draw.Color(.GREEN));
            } else {
                matrix.setPixel(@intCast(x), 1, 0, draw.Color(.RED));
            }
        } else {
            if (x >= 2 and x <= 4) {
                matrix.setPixel(@intCast(x), 1, 0, draw.Color(.GREEN));
            } else {
                matrix.setPixel(@intCast(x), 1, 0, draw.Color(.RED));
            }
        }
    }
    for (1..7) |y| {
        matrix.setPixel(1, @intCast(y), 0, draw.Color(.RED));
        matrix.setPixel(6, @intCast(y), 0, draw.Color(.RED));
    }
}

fn loadStateBox(game: Cyclone, win: bool, lose: bool) void {
    if (win) {
        draw.box(3, 3, 0, 2, 2, @intCast(2 * (game.state)), draw.Color(.GREEN));
    } else if (lose) {
        draw.box(3, 3, 0, 2, 2, @intCast(2 * (game.state)), draw.Color(.RED));
    } else {
        draw.box(3, 3, 0, 2, 2, @intCast(2 * (game.state)), draw.Color(.BLUE));
    }
}

fn checkClick(game: Cyclone) bool {
    var result: bool = false;
    if (game.state == 1) {
        result = (game.x >= 2) and (game.x <= 5) and (game.y == 0);
    } else {
        result = (game.x >= 3) and (game.x <= 4) and (game.y == 0);
    }
    return result;
}

// app entry point
fn appMain() callconv(.C) void {
    // NOTE: for random number generator uncomment the rand include,
    // and use deltaTime.timestamp() as a seed
    // rand.DefaultPrng.init(@intCast(deltaTime.timestamp())); <-- for seeding random

    var prng = std.rand.DefaultPrng.init(@intCast(deltaTime.timestamp()));
    const rand = prng.random();

    // struct variable managing state of the game
    var game: Cyclone = .{};

    // dt struct is usded for keeping tract of time between frames
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // time keeping vairiables to limit tickRate
    const tickRate: u32 = 60; // i.e. target fps or update rate
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // loop control variable
    var appRunning = true;

    // collision consts
    // matrix.upperBound;
    // matrix.lowerBound;

    // manages update speed
    var tickcount: i32 = 0;
    var waitcount: i32 = 0;
    var movement: i32 = 0;

    // gamestate variables
    var win: bool = false;
    var lose: bool = false;

    // TODO: replace true in while true with joystick press exit condition
    while (appRunning) {

        // checking for exit condition
        joystick.joystick_update();
        appRunning = !joystick.button_pressed();
        // NOTE: There are other ways to use dt for keeping track of render time.
        // This method will lock your update logic to the framerate of the display,
        // and limit the framefrate to a max value determined by tickRate
        timeSinceUpdate += dt.milli();
        if (timeSinceUpdate >= updateTime) {
            joystick.joystick_update();
            timeSinceUpdate = 0;

            // draw to the display
            // NOTE: must start with clearing the frame and end with
            // rendering the frame else the frame before last will remain
            matrix.clearFrame(draw.Color(.BLACK));

            if (game.showing_placement and !win and !lose) {
                if (waitcount < 30) {
                    waitcount += 1;
                } else {
                    waitcount = 0;
                    game.showing_placement = false;
                    game.state += 1;
                    if (game.state == 1 or game.state == 2) {
                        game.x = 6;
                        game.xVel = 1;
                        game.y = 0;
                        game.yVel = 0;
                    } else {
                        game.x = 5;
                        game.xVel = 1;
                        game.y = 0;
                        game.yVel = 0;
                    }
                }
            }

            if (button.pressed() and !game.showing_placement) {
                game.showing_placement = true;
                // rng like in the real world :eyes:
                if (game.state == 4 and checkClick(game)) {
                    if (rand.intRangeAtMost(i32, 0, 1) != 0) {
                        if (game.x == 3) {
                            game.x -= 1;
                        } else if (game.x == 4) {
                            game.x += 1;
                        }
                    }
                }
                if (checkClick(game)) {
                    if (game.state == 4) {
                        win = true;
                    }
                } else {
                    lose = true;
                }
                tickcount = 0;
            } else {
                tickcount += 1;
            }

            if (!win and !lose) {
                // movment update
                if (@rem(tickcount, game.getspeed()) == 0 and !game.showing_placement) {
                    game.x += game.xVel;
                    game.y += game.yVel;
                }

                // collision detection & resolution
                if (game.x >= matrix.upperBound and movement == 0) {
                    game.xVel = 0;
                    game.yVel = 1;
                    movement = 1;
                } else if (game.y >= matrix.upperBound and movement == 1) {
                    game.xVel = -1;
                    game.yVel = 0;
                    movement = 2;
                } else if (game.x <= matrix.lowerBound and movement == 2) {
                    game.xVel = 0;
                    game.yVel = -1;
                    movement = 3;
                } else if (game.y <= matrix.lowerBound and movement == 3) {
                    game.xVel = 1;
                    game.yVel = 0;
                    movement = 0;
                }
            }

            loadInnerRing(game);
            matrix.setPixel(game.x, game.y, 0, draw.Color(.YELLOW));
            loadStateBox(game, win, lose);

            if (restart.pressed()) {
                // resets game
                game = .{};
                // turns win/loss/change color flags off
                win = false;
                lose = false;
                tickcount = 0;
                waitcount = 0;
                movement = 0;
            }

            matrix.render();
        }
    }
}
