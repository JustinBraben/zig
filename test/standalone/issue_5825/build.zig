const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Test it");
    b.default_step = test_step;

    // Building for the msvc abi requires a native MSVC installation
    if (builtin.os.tag != .windows or builtin.cpu.arch != .x86_64) return;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .msvc,
    });
    const optimize: std.builtin.OptimizeMode = .Debug;
    const obj = b.addObject(.{
        .name = "issue_5825",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });

    const exe = b.addExecutable(.{
        .name = "issue_5825",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .optimize = optimize,
            .target = target,
        }),
    });
    exe.subsystem = .Console;
    exe.root_module.linkSystemLibrary("kernel32", .{});
    exe.root_module.linkSystemLibrary("ntdll", .{});
    exe.root_module.addObject(obj);

    // TODO: actually check the output
    _ = exe.getEmittedBin();

    test_step.dependOn(&exe.step);
}
