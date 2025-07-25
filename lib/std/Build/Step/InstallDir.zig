const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const Step = std.Build.Step;
const LazyPath = std.Build.LazyPath;
const InstallDir = @This();

step: Step,
options: Options,

pub const base_id: Step.Id = .install_dir;

pub const Options = struct {
    source_dir: LazyPath,
    install_dir: std.Build.InstallDir,
    install_subdir: []const u8,
    /// File paths which end in any of these suffixes will be excluded
    /// from being installed.
    exclude_extensions: []const []const u8 = &.{},
    /// Only file paths which end in any of these suffixes will be included
    /// in installation. `null` means all suffixes are valid for this option.
    /// `exclude_extensions` take precedence over `include_extensions`
    include_extensions: ?[]const []const u8 = null,
    /// File paths which end in any of these suffixes will result in
    /// empty files being installed. This is mainly intended for large
    /// test.zig files in order to prevent needless installation bloat.
    /// However if the files were not present at all, then
    /// `@import("test.zig")` would be a compile error.
    blank_extensions: []const []const u8 = &.{},

    fn dupe(opts: Options, b: *std.Build) Options {
        return .{
            .source_dir = opts.source_dir.dupe(b),
            .install_dir = opts.install_dir.dupe(b),
            .install_subdir = b.dupe(opts.install_subdir),
            .exclude_extensions = b.dupeStrings(opts.exclude_extensions),
            .include_extensions = if (opts.include_extensions) |incs| b.dupeStrings(incs) else null,
            .blank_extensions = b.dupeStrings(opts.blank_extensions),
        };
    }
};

pub fn create(owner: *std.Build, options: Options) *InstallDir {
    const install_dir = owner.allocator.create(InstallDir) catch @panic("OOM");
    install_dir.* = .{
        .step = Step.init(.{
            .id = base_id,
            .name = owner.fmt("install {s}/", .{options.source_dir.getDisplayName()}),
            .owner = owner,
            .makeFn = make,
        }),
        .options = options.dupe(owner),
    };
    options.source_dir.addStepDependencies(&install_dir.step);
    return install_dir;
}

fn make(step: *Step, options: Step.MakeOptions) !void {
    _ = options;
    const b = step.owner;
    const install_dir: *InstallDir = @fieldParentPtr("step", step);
    step.clearWatchInputs();
    const arena = b.allocator;
    const dest_prefix = b.getInstallPath(install_dir.options.install_dir, install_dir.options.install_subdir);
    const src_dir_path = install_dir.options.source_dir.getPath3(b, step);
    const need_derived_inputs = try step.addDirectoryWatchInput(install_dir.options.source_dir);
    var src_dir = src_dir_path.root_dir.handle.openDir(src_dir_path.subPathOrDot(), .{ .iterate = true }) catch |err| {
        return step.fail("unable to open source directory '{f}': {s}", .{
            src_dir_path, @errorName(err),
        });
    };
    defer src_dir.close();
    var it = try src_dir.walk(arena);
    var all_cached = true;
    next_entry: while (try it.next()) |entry| {
        for (install_dir.options.exclude_extensions) |ext| {
            if (mem.endsWith(u8, entry.path, ext)) continue :next_entry;
        }
        if (install_dir.options.include_extensions) |incs| {
            for (incs) |inc| {
                if (mem.endsWith(u8, entry.path, inc)) break;
            } else {
                continue :next_entry;
            }
        }

        const src_path = try install_dir.options.source_dir.join(b.allocator, entry.path);
        const dest_path = b.pathJoin(&.{ dest_prefix, entry.path });
        switch (entry.kind) {
            .directory => {
                if (need_derived_inputs) _ = try step.addDirectoryWatchInput(src_path);
                const p = try step.installDir(dest_path);
                all_cached = all_cached and p == .existed;
            },
            .file => {
                for (install_dir.options.blank_extensions) |ext| {
                    if (mem.endsWith(u8, entry.path, ext)) {
                        try b.truncateFile(dest_path);
                        continue :next_entry;
                    }
                }

                const p = try step.installFile(src_path, dest_path);
                all_cached = all_cached and p == .fresh;
            },
            else => continue,
        }
    }

    step.result_cached = all_cached;
}
