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
        Button_A.memory_byte_shift_one();
    } else {
        Button_A.memory_byte_shift_zero();
    }
    if (Button_A.memory_byte_full() and Button_A.pressed() == false) {
        Button_A.update_pressed();
    }

    // button_b memory byte
    if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_3 != 0) {
        Button_B.memory_byte_shift_one();
    } else {
        Button_B.memory_byte_shift_zero();
    }
    if (Button_B.memory_byte_full() and Button_B.pressed() == false) {
        Button_B.update_pressed();
    }

    // joystick memory byte
    if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_2 != 0) {
        Joystick.memory_byte_shift_one(.BUTTON);
    } else {
        Joystick.memory_byte_shift_zero(.BUTTON);
    }
    if (Joystick.memory_byte_full(.BUTTON) and Joystick.button_pressed(.BUTTON) == false) {
        Joystick.update_cur_value(.BUTTON);
    }
}
