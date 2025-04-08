const std = @import("std");
const microzig = @import("microzig");
const CSource = std.Build.Module.CSourceFile;

const MicroBuild = microzig.MicroBuild(.{
    .stm32 = true,
});

pub fn build(b: *std.Build) !void {
    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;
    const mzTarget: *const microzig.Target = mb.ports.stm32.chips.STM32F091RC;
    var options = b.addOptions();
    // const zigTarget = b.resolveTargetQuery(mzTarget.chip.cpu);

    const optimize = b.standardOptimizeOption(.{});

    const firmware = mb.add_firmware(.{
        .name = "hello",
        .target = mzTarget,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    // -------
    // Compile the C files
    // -------
    var cApps = std.ArrayList([]const u8).init(b.allocator);

    const c_compile_flags = [_][]const u8{ "-DSTM32F0", "-DSTM32F091xC" };

    const cfile_dir = try std.fs.openDirAbsolute(b.path("cfiles/").getPath(b), .{ .iterate = true });
    var cfile_walker = try cfile_dir.walk(b.allocator);
    defer cfile_walker.deinit();
    while (try cfile_walker.next()) |entry| {
        if (entry.kind == .file) {
            if (std.mem.eql(u8, entry.basename[entry.basename.len - 2 ..], ".c")) {
                const dir_path = try entry.dir.realpathAlloc(b.allocator, ".");
                const abspath = try std.fs.path.resolve(b.allocator, &.{ dir_path, entry.basename });
                firmware.add_c_source_file(CSource{ .file = .{ .cwd_relative = abspath }, .flags = &c_compile_flags });

                // if it's in the apps dir
                if (std.mem.endsWith(u8, dir_path, "apps")) {
                    try cApps.append(try b.allocator.dupe(u8, entry.basename[0 .. entry.basename.len - 2]));
                }
            }
        }
    }
    // Add CMSIS headers
    firmware.add_include_path(b.path("CMSIS_5/CMSIS/Core/Include/"));
    firmware.add_include_path(b.path("cmsis-device-f0/Include/"));
    firmware.app_mod.addIncludePath(b.path("CMSIS_5/CMSIS/Core/Include/"));
    firmware.app_mod.addIncludePath(b.path("cmsis-device-f0/Include/"));
    firmware.add_include_path(b.path("include/"));
    firmware.app_mod.addIncludePath(b.path("include/"));
    // Add cApps option
    options.addOption([]const []const u8, "cApps", try cApps.toOwnedSlice());
    firmware.app_mod.addOptions("options", options);

    // -------
    // Firmware install step
    // -------
    const fw_install_step = mb.add_install_firmware(firmware, .{ .format = .elf });
    b.getInstallStep().dependOn(&fw_install_step.step);

    // -----------
    // Flash step
    // -----------
    //
    const openocd = try b.findProgram(&.{"openocd"}, &.{"C:\\Users\\jnbta\\.platformio\\packages\\tool-openocd\\bin"});

    // Absolute path to openocd.cfg
    const openocdcfg = b.path("build/openocd.cfg").getPath(b);
    const firmwarepath_raw = b.getInstallPath(fw_install_step.dir, fw_install_step.dest_rel_path);

    const firmwarepath = try std.mem.replaceOwned(u8, b.allocator, firmwarepath_raw, "\\", "\\\\");

    //std.debug.print("{s}", .{firmwarepath});
    const openocdcmds = try std.fmt.allocPrint(b.allocator, "program {s} verify reset exit", .{firmwarepath});

    const flash_elf = b.addSystemCommand(&[_][]const u8{ openocd, "-f", openocdcfg, "-c", openocdcmds });

    flash_elf.step.dependOn(b.getInstallStep());

    const flash_step = b.step("flash", "Flash microcontroller with .elf via openocd");
    flash_step.dependOn(&flash_elf.step);

    // ---------
    // Check step (for zls)
    // ---------
    // See: https://zigtools.org/zls/guides/build-on-save/
    // Need to redefine same firmware
    const firmware_check = mb.add_firmware(.{
        .name = "compcheck",
        .target = mb.ports.stm32.chips.STM32F091RC,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/main.zig"),
    });
    const check = b.step("check", "Check if firmware compiles");
    check.dependOn(&firmware_check.artifact.step);
}
