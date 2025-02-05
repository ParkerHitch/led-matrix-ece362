const microzig = @import("microzig");
const RCC = microzig.chip.peripherals.RCC;
const FLASH = microzig.chip.peripherals.FLASH;

pub fn internal_clock() void {
    // Disable HSE to allow use of the GPIOs
    RCC.CR.modify(.{ .HSEON = 0b0 });
    // Enable Prefetch Buffer and set Flash Latency
    FLASH.ACR.modify(.{
        .PRFTBE = 1,
        .LATENCY = .WS1,
    });
    RCC.CFGR.modify(.{
        // HCLK = SYSCLK
        .HPRE = .Div1,
        // PCLK = HCLK
        .PPRE = .Div1,
        // PLL configuration = (HSI/2) * 12 = ~48 MHz
        .PLLSRC = .HSI_Div2,
        .PLLXTPRE = .Div1,
        .PLLMUL = .Mul12,
    });
    // Enable PLL
    RCC.CR.modify(.{
        .PLLON = 1,
    });
    // Wait till PLL is ready
    while ((RCC.CR.read().PLLRDY) == 0) {}
    // Select PLL as system clock source
    RCC.CFGR.modify(.{
        .SW = .PLL1_P,
    });
    // Wait till PLL is used as system clock source
    while ((RCC.CFGR.read().SWS) != .PLL1_P) {}
}
