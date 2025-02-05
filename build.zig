const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .stm32 = true,
});

pub fn build(b: *std.Build) !void {
    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const firmware = mb.add_firmware(.{
        .name = "hello",
        .target = mb.ports.stm32.chips.STM32F091RC,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/main.zig"),
    });
    const fw_install_step = mb.add_install_firmware(firmware, .{ .format = .elf });
    b.getInstallStep().dependOn(&fw_install_step.step);

    // Flash step

    // Absolute path to openocd.cfg
    const openocdcfg = b.path("build/openocd.cfg").getPath(b);
    const firmwarepath = b.getInstallPath(fw_install_step.dir, fw_install_step.dest_rel_path);
    const openocdcmds = try std.fmt.allocPrint(b.allocator, "program {s} verify reset exit", .{firmwarepath});

    const flash_elf = b.addSystemCommand(&[_][]const u8{ "openocd", "-f", openocdcfg, "-c", openocdcmds });

    flash_elf.step.dependOn(b.getInstallStep());

    const flash_step = b.step("flash", "Flash microcontroller with .elf via openocd");
    flash_step.dependOn(&flash_elf.step);
}
