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

    .name = "Stacker",
    .authorfirst = "Richard",
    .authorlast = "Ye",
};

const StackLayer = struct {
    // Changing the initialized values in this struct will change the starting point and size of the layer
    // x and y represent bottom left hand corner of stack block
    x: i32 = 2,
    y: i32 = 2,

    xLen: i32 = 4,
    yLen: i32 = 4,

    color: draw.ColorEnum = .BLUE,
};

const Stack = struct {
    LayerArray: [8]StackLayer = [_]StackLayer{.{}} ** 8,

    height: i32 = 0,
};

fn DrawStackLayer(layer: StackLayer, z: i32) void {
    for (@intCast(layer.x)..@intCast(layer.x + layer.xLen)) |x| {
        for (@intCast(layer.y)..@intCast(layer.y + layer.yLen)) |y| {
            matrix.setPixel(@intCast(x), @intCast(y), @intCast(z), draw.Color(layer.color));
        }
    }
}

fn DrawStack(stack: Stack) void {
    for (0..@intCast(stack.height)) |z| {
        DrawStackLayer(stack.LayerArray[z], @intCast(z));
    }
}

// only use when stack.height != 0
fn CheckPlacement(stack: Stack) bool {
    // checks if lower bound of x is between the previous layer's upper and lower bounds
    const lowerX: bool = (stack.LayerArray[@intCast(stack.height)].x >= stack.LayerArray[@intCast(stack.height - 1)].x) and (stack.LayerArray[@intCast(stack.height)].x <= (stack.LayerArray[@intCast(stack.height - 1)].x + stack.LayerArray[@intCast(stack.height - 1)].xLen - 1));
    // checks if upper bound of x is between the previous layer's upper and lower bounds
    const upperX: bool = ((stack.LayerArray[@intCast(stack.height)].x + stack.LayerArray[@intCast(stack.height)].xLen - 1) >= (stack.LayerArray[@intCast(stack.height - 1)].x)) and ((stack.LayerArray[@intCast(stack.height)].x + stack.LayerArray[@intCast(stack.height)].xLen - 1) <= (stack.LayerArray[@intCast(stack.height - 1)].x + stack.LayerArray[@intCast(stack.height - 1)].xLen - 1));
    // checks if lower bound of y is between the previous layer's upper and lower bounds
    const lowerY: bool = (stack.LayerArray[@intCast(stack.height)].y >= stack.LayerArray[@intCast(stack.height - 1)].y) and (stack.LayerArray[@intCast(stack.height)].y <= (stack.LayerArray[@intCast(stack.height - 1)].y + stack.LayerArray[@intCast(stack.height - 1)].yLen - 1));
    // checks if upper bound of y is between the previous layer's upper and lower bounds
    const upperY: bool = ((stack.LayerArray[@intCast(stack.height)].y + stack.LayerArray[@intCast(stack.height)].yLen - 1) >= (stack.LayerArray[@intCast(stack.height - 1)].y)) and ((stack.LayerArray[@intCast(stack.height)].y + stack.LayerArray[@intCast(stack.height)].yLen - 1) <= (stack.LayerArray[@intCast(stack.height - 1)].y + stack.LayerArray[@intCast(stack.height - 1)].yLen - 1));
    return ((lowerX or upperX) and (lowerY or upperY));
}

// app entry point
fn appMain() callconv(.C) void {
    // NOTE: for random number generator uncomment the rand include,
    // and use deltaTime.timestamp() as a seed
    // rand.DefaultPrng.init(@intCast(deltaTime.timestamp())); <-- for seeding random

    // dt struct is usded for keeping tract of time between frames
    var dt: deltaTime.DeltaTime = .{};
    dt.start();

    // time keeping vairiables to limit tickRate
    const tickRate: u32 = 60; // i.e. target fps or update rate
    const updateTime: u32 = 1000 / tickRate; // 1000 ms * (period of a tick)
    var timeSinceUpdate: u32 = 0;

    // loop control variable
    var appRunning: bool = true;
    // var button_pressed: bool = false;
    // var restart_pressed: bool = false;

    // collision consts
    const matrixLowerBound: i32 = 0;
    const matrixUpperBound: i32 = 7;

    // yz-plane x pos and velocity
    var xVel: i32 = 1; // units per tick
    var yVel: i32 = 0;

    // initializes stack
    var stack: Stack = .{};

    // stores win and lose conditions
    var win: bool = false;
    var lose: bool = false;
    var endColorChange: bool = false;
    var placed: bool = false;

    // initializes placement info
    var lowerX: bool = false;
    var upperX: bool = false;
    var lowerY: bool = false;
    var upperY: bool = false;

    // variable for changing speed of top layer
    var tickcount: i32 = 0;

    // TODO: replace true in while true with joystick press exit condition
    while (appRunning) {
        // checking for exit condition
        joystick.joystick_update();
        appRunning = !joystick.button_pressed();

        // checking for button press
        // button_pressed = button.pressed();

        // checking for restart press
        // restart_pressed = restart.pressed();

        // takes one cycle to place then restart velocity for moving layer
        if (placed) {
            xVel = 1;
            yVel = 0;
            placed = false;
        }

        // changes colors of stack on win and loss
        if (lose and !endColorChange) {
            for (0..@intCast(stack.height)) |z| {
                stack.LayerArray[z].color = .RED;
            }
            endColorChange = true;
        } else if (win and !endColorChange) {
            for (0..@intCast(stack.height)) |z| {
                stack.LayerArray[z].color = .GREEN;
            }
            endColorChange = true;
        }

        // NOTE: There are other ways to use dt for keeping track of render time.
        // This method will lock your update logic to the framerate of the display,
        // and limit the framefrate to a max value determined by tickRate
        timeSinceUpdate += dt.milli();

        matrix.clearFrame(draw.Color(.BLACK));

        if (timeSinceUpdate >= updateTime) {
            timeSinceUpdate = 0;
            // logic for stacking when button pressed
            if (button.pressed()) {
                tickcount = 0;
                // switching to moving in y
                if (xVel != 0) {
                    xVel = 0;
                    yVel = 1;
                }
                // stops to plant the layer
                else if (yVel != 0) {
                    xVel = 0;
                    yVel = 0;
                    if (stack.height > 0) {
                        if (CheckPlacement(stack)) {
                            // edit placed layer
                            // copy paste of checkplacement checks
                            // checks if lower bound of x is between the previous layer's upper and lower bounds
                            lowerX = (stack.LayerArray[@intCast(stack.height)].x >= stack.LayerArray[@intCast(stack.height - 1)].x) and (stack.LayerArray[@intCast(stack.height)].x <= (stack.LayerArray[@intCast(stack.height - 1)].x + stack.LayerArray[@intCast(stack.height - 1)].xLen - 1));
                            // checks if upper bound of x is between the previous layer's upper and lower bounds
                            upperX = ((stack.LayerArray[@intCast(stack.height)].x + stack.LayerArray[@intCast(stack.height)].xLen - 1) >= (stack.LayerArray[@intCast(stack.height - 1)].x)) and ((stack.LayerArray[@intCast(stack.height)].x + stack.LayerArray[@intCast(stack.height)].xLen - 1) <= (stack.LayerArray[@intCast(stack.height - 1)].x + stack.LayerArray[@intCast(stack.height - 1)].xLen - 1));
                            // checks if lower bound of y is between the previous layer's upper and lower bounds
                            lowerY = (stack.LayerArray[@intCast(stack.height)].y >= stack.LayerArray[@intCast(stack.height - 1)].y) and (stack.LayerArray[@intCast(stack.height)].y <= (stack.LayerArray[@intCast(stack.height - 1)].y + stack.LayerArray[@intCast(stack.height - 1)].yLen - 1));
                            // checks if upper bound of y is between the previous layer's upper and lower bounds
                            upperY = ((stack.LayerArray[@intCast(stack.height)].y + stack.LayerArray[@intCast(stack.height)].yLen - 1) >= (stack.LayerArray[@intCast(stack.height - 1)].y)) and ((stack.LayerArray[@intCast(stack.height)].y + stack.LayerArray[@intCast(stack.height)].yLen - 1) <= (stack.LayerArray[@intCast(stack.height - 1)].y + stack.LayerArray[@intCast(stack.height - 1)].yLen - 1));

                            // if x lower bound is lower than the stack, replace it
                            if (!lowerX) {
                                stack.LayerArray[@intCast(stack.height)].xLen = stack.LayerArray[@intCast(stack.height)].x + stack.LayerArray[@intCast(stack.height)].xLen - stack.LayerArray[@intCast(stack.height - 1)].x;
                                stack.LayerArray[@intCast(stack.height)].x = stack.LayerArray[@intCast(stack.height - 1)].x;
                            }
                            // if x upper bound is higher than the stack, replace it
                            if (!upperX) {
                                stack.LayerArray[@intCast(stack.height)].xLen = (stack.LayerArray[@intCast(stack.height - 1)].x + stack.LayerArray[@intCast(stack.height - 1)].xLen) - stack.LayerArray[@intCast(stack.height)].x;
                            }
                            // if y lower bound is lower than the bound, replace it
                            if (!lowerY) {
                                stack.LayerArray[@intCast(stack.height)].yLen = stack.LayerArray[@intCast(stack.height)].y + stack.LayerArray[@intCast(stack.height)].yLen - stack.LayerArray[@intCast(stack.height - 1)].y;
                                stack.LayerArray[@intCast(stack.height)].y = stack.LayerArray[@intCast(stack.height - 1)].y;
                            }
                            // if y upper bound is lower than the bound, replace it
                            if (!upperY) {
                                stack.LayerArray[@intCast(stack.height)].yLen = (stack.LayerArray[@intCast(stack.height - 1)].y + stack.LayerArray[@intCast(stack.height - 1)].yLen) - stack.LayerArray[@intCast(stack.height)].y;
                            }
                            // start new layer
                            stack.height += 1;
                            if (stack.height >= 8) {
                                win = true;
                            } else {
                                // start new layer and sets size to previous layer
                                stack.LayerArray[@intCast(stack.height)].x = stack.LayerArray[@intCast(stack.height - 1)].x;
                                stack.LayerArray[@intCast(stack.height)].xLen = stack.LayerArray[@intCast(stack.height - 1)].xLen;
                                stack.LayerArray[@intCast(stack.height)].y = stack.LayerArray[@intCast(stack.height - 1)].y;
                                stack.LayerArray[@intCast(stack.height)].yLen = stack.LayerArray[@intCast(stack.height - 1)].yLen;
                                placed = true;
                            }
                        } else {
                            lose = true;
                        }
                    } else {
                        stack.height += 1;
                        stack.LayerArray[@intCast(stack.height)].x = stack.LayerArray[@intCast(stack.height - 1)].x;
                        stack.LayerArray[@intCast(stack.height)].xLen = stack.LayerArray[@intCast(stack.height - 1)].xLen;
                        stack.LayerArray[@intCast(stack.height)].y = stack.LayerArray[@intCast(stack.height - 1)].y;
                        stack.LayerArray[@intCast(stack.height)].yLen = stack.LayerArray[@intCast(stack.height - 1)].yLen;
                        placed = true;
                    }
                }
            } else {
                tickcount += 1;
            }

            // only change / show top stack if haven't won or lost
            if (!win and !lose) {
                // movment update
                if ((@rem(tickcount, (1 + 2 * (7 - stack.height))) == 0) and !placed) { //(8 - stack.height)
                    stack.LayerArray[@intCast(stack.height)].x += xVel;
                    stack.LayerArray[@intCast(stack.height)].y += yVel;
                }

                // collision detection & resolution
                if ((stack.LayerArray[@intCast(stack.height)].x + stack.LayerArray[@intCast(stack.height)].xLen - 1) > matrixUpperBound) {
                    stack.LayerArray[@intCast(stack.height)].x = matrixUpperBound - stack.LayerArray[@intCast(stack.height)].xLen;
                    xVel *= -1;
                } else if (stack.LayerArray[@intCast(stack.height)].x < matrixLowerBound) {
                    stack.LayerArray[@intCast(stack.height)].x = matrixLowerBound;
                    xVel *= -1;
                }
                if ((stack.LayerArray[@intCast(stack.height)].y + stack.LayerArray[@intCast(stack.height)].yLen - 1) > matrixUpperBound) {
                    stack.LayerArray[@intCast(stack.height)].y = matrixUpperBound - stack.LayerArray[@intCast(stack.height)].yLen;
                    yVel *= -1;
                } else if (stack.LayerArray[@intCast(stack.height)].y < matrixLowerBound) {
                    stack.LayerArray[@intCast(stack.height)].y = matrixLowerBound;
                    yVel *= -1;
                }
                DrawStackLayer(stack.LayerArray[@intCast(stack.height)], 7);
            }

            // draw to the display
            // NOTE: must start with clearing the frame and end with
            // rendering the frame else the frame before last will remain
            DrawStack(stack);

            if (restart.pressed()) {
                // resets stack
                stack = .{};
                // turns win/loss/change color flags off
                win = false;
                lose = false;
                endColorChange = false;
                // restart movement
                xVel = 1;
                yVel = 0;
            }

            matrix.render();
        }
    }
}
