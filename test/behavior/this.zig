const std = @import("std");
const expect = std.testing.expect;
const builtin = @import("builtin");

const module = @This();

fn Point(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,

        fn addOne(self: *Self) void {
            self.x += 1;
            self.y += 1;
        }
    };
}

fn add(x: i32, y: i32) i32 {
    return x + y;
}

test "this refer to module call private fn" {
    try expect(module.add(1, 2) == 3);
}

test "this refer to container" {
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO

    var pt: Point(i32) = undefined;
    pt.x = 12;
    pt.y = 34;
    Point(i32).addOne(&pt);
    try expect(pt.x == 13);
    try expect(pt.y == 35);
}

const State = struct {
    const Self = @This();
    enter: *const fn (previous: ?Self) void,
};

fn prev(p: ?State) void {
    expect(p == null) catch @panic("test failure");
}

test "this used as optional function parameter" {
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    var global: State = undefined;
    global.enter = prev;
    global.enter(null);
}

test "@This() in opaque" {
    const T = opaque {
        const Self = @This();
    };
    comptime std.debug.assert(T.Self == T);
}
