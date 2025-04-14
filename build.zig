const std = @import("std");
const builtin = @import("builtin");
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

    // ----
    // Find zig apps
    // ----
    var zigApps = std.ArrayList([]const u8).init(b.allocator);
    var zigAppsDir = try std.fs.openDirAbsolute(b.path("src/apps").getPath(b), .{ .iterate = true });
    var zappsIter = zigAppsDir.iterate();
    while (try zappsIter.next()) |app| {
        if (app.kind == .file and std.mem.endsWith(u8, app.name, ".zig")) {
            if (std.mem.eql(u8, app.name, "index.zig")) {
                continue;
            }
            try zigApps.append(try b.allocator.dupe(u8, app.name[0 .. app.name.len - 4]));
        }
    }

    // -------
    // Compile the C files
    // -------
    var cApps = std.ArrayList([]const u8).init(b.allocator);
    var cfileList = std.ArrayList([]const u8).init(b.allocator);

    const cfile_dir = try std.fs.openDirAbsolute(b.path("cfiles/").getPath(b), .{ .iterate = true });
    var cfile_walker = try cfile_dir.walk(b.allocator);
    defer cfile_walker.deinit();
    while (try cfile_walker.next()) |entry| {
        if (entry.kind == .file) {
            if (std.mem.eql(u8, entry.basename[entry.basename.len - 2 ..], ".c")) {
                const dir_path = try entry.dir.realpathAlloc(b.allocator, ".");
                const abspath = try std.fs.path.resolve(b.allocator, &.{ dir_path, entry.basename });

                try cfileList.append(abspath);

                // if it's in the apps dir
                if (std.mem.endsWith(u8, dir_path, "apps")) {
                    try cApps.append(try b.allocator.dupe(u8, entry.basename[0 .. entry.basename.len - 2]));
                }
            }
        }
    }
    // Now that we know how many apps we have we can define the macro properly
    const c_compile_flags = [_][]const u8{ "-DSTM32F0", "-DSTM32F091xC", try std.fmt.allocPrint(b.allocator, "-DMAXAPPS={}", .{cApps.items.len + zigApps.items.len}) };
    for (cfileList.items) |abspath| {
        firmware.add_c_source_file(CSource{ .file = .{ .cwd_relative = abspath }, .flags = &c_compile_flags });
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

    // -------
    // Compile the asm files
    // -------
    const asmfile_dir = try std.fs.openDirAbsolute(b.path("asmfiles/").getPath(b), .{ .iterate = true });
    var asmfile_iterator = asmfile_dir.iterate();
    while (try asmfile_iterator.next()) |entry| {
        if (entry.kind == .file) {
            if (std.mem.eql(u8, entry.name[entry.name.len - 2 ..], ".S")) {
                firmware.app_mod.addAssemblyFile(b.path(try std.fmt.allocPrint(b.allocator, "asmfiles/{s}", .{entry.name})));
            } else {
                std.debug.print("Error! Found non-asm file: {s} in asmfiles dir. Please use .S file extension", .{entry.name});
            }
        }
    }
    options.addOption([]const []const u8, "zigApps", try zigApps.toOwnedSlice());
    // TODO:
    // Auto-generate index file

    // ------
    // Make sure options are available to the app
    // -----
    firmware.app_mod.addOptions("options", options);

    // -------
    // Firmware install step
    // -------
    const fw_install_step = mb.add_install_firmware(firmware, .{ .format = .elf });
    b.getInstallStep().dependOn(&fw_install_step.step);

    // -----------
    // Flash step
    // -----------

    var envMap = try std.process.getEnvMap(b.allocator);
    defer envMap.deinit();
    const homePath =
        if (builtin.target.os.tag == .macos or builtin.target.os.tag == .linux) envMap.get("HOME").? else if (builtin.target.os.tag == .windows) envMap.get("USERPROFILE").? else @compileError("Building on unsupported OS. Like actually what are you doing? Why are you not running windows, mac, or linux?");

    const openocdPath = try std.fs.path.resolve(b.allocator, &.{ homePath, ".platformio", "packages", "tool-openocd", "bin" });
    //std.debug.print("Home dir: {s}\nOpenocd dir: {s}\n", .{ homePath, openocdPath });
    defer b.allocator.free(openocdPath);
    const openocd = try b.findProgram(&.{"openocd"}, &.{openocdPath});

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
