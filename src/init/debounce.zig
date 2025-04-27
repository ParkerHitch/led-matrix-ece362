const microzig = @import("microzig");
const cImport = @import("../cImport.zig");
const Joystick = @import("../subsystems/joystick.zig");
const Button_A = @import("../subsystems/button_a.zig");
const Button_B = @import("../subsystems/button_b.zig");
const Screen = @import("../subsystems/Screen.zig");
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

    // // button_a memory byte
    // if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_4) {
    //     Button_A.memory_byte = (Button_A.memory_byte << 1) + 1;
    // } else {
    //     Button_A.memory_byte = (Button_A.memory_byte << 1);
    // }

    // // button_b memory byte
    // if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_3) {
    //     Button_B.memory_byte = (Button_B.memory_byte << 1) + 1;
    // } else {
    //     Button_B.memory_byte = (Button_B.memory_byte << 1);
    // }

    // // joystick memory byte
    // if (cImport.cmsis.GPIOC.*.IDR & cImport.cmsis.GPIO_IDR_4) {
    //     Joystick.memory_byte = (Joystick.memory_byte << 1) + 1;
    // } else {
    //     Joystick.memory_byte = (Joystick.memory_byte << 1);
    // }
}
