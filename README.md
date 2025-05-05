# The Cube, a Voxel Display

Originally created as a final project for Purdue's ECE 36200, The Cube is a 3D display made up of 512 RGB leds, plus an external hand-held controller for user interaction.
This codebase features the drivers required to interact with peripherals and numerous apps to showcase its capabilities.

## Features

- Fixed point, quaternion-based complementary filter for 6-axis IMU.
- Rendering API with support for double-buffering.
- Interrupt-based input buffering.
- Interrupt-free matrix driver via DMA, SPI, and Timer peripherals.
- Semi-complete fixed point library with some cool metaprogramming.

## Media

https://github.com/user-attachments/assets/8b256a77-d5e7-4344-ab03-db80d9f11f41

*Showcase Video*

![Second award in the course-projects categoty in the Purdue ECE Spark challenge](/media/SparkSecond.jpg)
*Second place in the Purdue ECE Spark challenge*


## Dependencies

Libraries are lame, so we tried to keep the project as dependency-free as possible.
As a result, we only depend on CMSIS and Microzig for basic MMIO address definitions, a linker script, and runtime initialization.

No HAL and no libc/newlib!

<!-- ## Building -->
<!---->
<!-- For most systems, a simple `zig build` should work just fine. To flash, you must have openocd installed (either via platformio or just in your normal PATH), and you can hit `zig build flash`. -->
<!-- As of Zig 0.13 this project cannot be built in release mode, as there is a bug with projects with both C and Zig and link-time optimization not working. I believe this is fixed in zig 0.14, but we did not migrate to this due to a lack of support from microzig (they support it now, but this was) -->

## Team Members
- John Burns: Most of the physical construction, and the app framework.
- Parker Hitchcock: Codebase foundations, matrix display driver, and IMU driver.
- Micah Samuel: Joystick support and app development.
- Richard Ye: Circuit design and menu system.
