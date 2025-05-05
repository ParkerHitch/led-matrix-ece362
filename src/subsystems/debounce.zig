const microzig = @import("microzig");
const cImport = @import("../cImport.zig");
const Joystick = @import("../subsystems/joystick.zig");
const Button_A = @import("../subsystems/button_a.zig");
const Button_B = @import("../subsystems/button_b.zig");
const Screen = @import("../subsystems/screen.zig");
const cmsis = cImport.cmsis;
const peripherals = microzig.chip.peripherals;
const periph_types = microzig.chip.types.peripherals;
const RCC = peripherals.RCC;
const TIM14 = peripherals.TIM14;
const GPIOC = peripherals.GPIOC;

pub export fn TIM14_IRQHandler() callconv(.C) void {
    TIM14.SR.modify(.{
        .UIF = 0,
    });

    // button_a memory byte
    if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_4 != 0) {
        Button_A.memory_byte_shift(1);
    } else {
        Button_A.memory_byte_shift(0);
    }
    if (Button_A.memory_byte_full() and Button_A.cur() == false) {
        Button_A.update_pressed();
    }

    // button_b memory byte
    if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_3 != 0) {
        Button_B.memory_byte_shift(1);
    } else {
        Button_B.memory_byte_shift(0);
    }
    if (Button_B.memory_byte_full() and Button_B.cur() == false) {
        Button_B.update_pressed();
    }

    // joystick memory byte
    if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_2 != 0) {
        Joystick.memory_byte_shift(.BUTTON, 1);
    } else {
        Joystick.memory_byte_shift(.BUTTON, 0);
    }
    if (Joystick.memory_byte_full(.BUTTON) and Joystick.cur(.BUTTON) == false) {
        Joystick.update_cur_value(.BUTTON);
    }

    // up memory byte
    if (Joystick.is_in_range(.UP)) {
        Joystick.memory_byte_shift(.UP, 1);
    } else {
        Joystick.memory_byte_shift(.UP, 0);
    }
    if (Joystick.memory_byte_full(.UP) and Joystick.cur(.UP) == false) {
        Joystick.update_cur_value(.UP);
    }

    // down memory byte
    if (Joystick.is_in_range(.DOWN)) {
        Joystick.memory_byte_shift(.DOWN, 1);
    } else {
        Joystick.memory_byte_shift(.DOWN, 0);
    }
    if (Joystick.memory_byte_full(.DOWN) and Joystick.cur(.DOWN) == false) {
        Joystick.update_cur_value(.DOWN);
    }

    // left memory byte
    if (Joystick.is_in_range(.LEFT)) {
        Joystick.memory_byte_shift(.LEFT, 1);
    } else {
        Joystick.memory_byte_shift(.LEFT, 0);
    }
    if (Joystick.memory_byte_full(.LEFT) and Joystick.cur(.LEFT) == false) {
        Joystick.update_cur_value(.LEFT);
    }

    // right memory byte
    if (Joystick.is_in_range(.RIGHT)) {
        Joystick.memory_byte_shift(.RIGHT, 1);
    } else {
        Joystick.memory_byte_shift(.RIGHT, 0);
    }
    if (Joystick.memory_byte_full(.RIGHT) and Joystick.cur(.RIGHT) == false) {
        Joystick.update_cur_value(.RIGHT);
    }
}
