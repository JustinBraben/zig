const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;

const Type = std.builtin.Type;
const TypeId = std.builtin.TypeId;

const assert = std.debug.assert;
const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

test "type info: integer, floating point type info" {
    try testIntFloat();
    try comptime testIntFloat();
}

fn testIntFloat() !void {
    const u8_info = @typeInfo(u8);
    try expect(u8_info == .int);
    try expect(u8_info.int.signedness == .unsigned);
    try expect(u8_info.int.bits == 8);

    const f64_info = @typeInfo(f64);
    try expect(f64_info == .float);
    try expect(f64_info.float.bits == 64);
}

test "type info: optional type info" {
    try testOptional();
    try comptime testOptional();
}

fn testOptional() !void {
    const null_info = @typeInfo(?void);
    try expect(null_info == .optional);
    try expect(null_info.optional.child == void);
}

test "type info: C pointer type info" {
    try testCPtr();
    try comptime testCPtr();
}

fn testCPtr() !void {
    const ptr_info = @typeInfo([*c]align(4) const i8);
    try expect(ptr_info == .pointer);
    try expect(ptr_info.pointer.size == .c);
    try expect(ptr_info.pointer.is_const);
    try expect(!ptr_info.pointer.is_volatile);
    try expect(ptr_info.pointer.alignment == 4);
    try expect(ptr_info.pointer.child == i8);
}

test "type info: value is correctly copied" {
    comptime {
        var ptrInfo = @typeInfo([]u32);
        ptrInfo.pointer.size = .one;
        try expect(@typeInfo([]u32).pointer.size == .slice);
    }
}

test "type info: tag type, void info" {
    try testBasic();
    try comptime testBasic();
}

fn testBasic() !void {
    try expect(@typeInfo(Type).@"union".tag_type == TypeId);
    const void_info = @typeInfo(void);
    try expect(void_info == TypeId.void);
    try expect(void_info.void == {});
}

test "type info: pointer type info" {
    try testPointer();
    try comptime testPointer();
}

fn testPointer() !void {
    const u32_ptr_info = @typeInfo(*u32);
    try expect(u32_ptr_info == .pointer);
    try expect(u32_ptr_info.pointer.size == .one);
    try expect(u32_ptr_info.pointer.is_const == false);
    try expect(u32_ptr_info.pointer.is_volatile == false);
    try expect(u32_ptr_info.pointer.alignment == @alignOf(u32));
    try expect(u32_ptr_info.pointer.child == u32);
    try expect(u32_ptr_info.pointer.sentinel() == null);
}

test "type info: unknown length pointer type info" {
    try testUnknownLenPtr();
    try comptime testUnknownLenPtr();
}

fn testUnknownLenPtr() !void {
    const u32_ptr_info = @typeInfo([*]const volatile f64);
    try expect(u32_ptr_info == .pointer);
    try expect(u32_ptr_info.pointer.size == .many);
    try expect(u32_ptr_info.pointer.is_const == true);
    try expect(u32_ptr_info.pointer.is_volatile == true);
    try expect(u32_ptr_info.pointer.sentinel() == null);
    try expect(u32_ptr_info.pointer.alignment == @alignOf(f64));
    try expect(u32_ptr_info.pointer.child == f64);
}

test "type info: null terminated pointer type info" {
    try testNullTerminatedPtr();
    try comptime testNullTerminatedPtr();
}

fn testNullTerminatedPtr() !void {
    const ptr_info = @typeInfo([*:0]u8);
    try expect(ptr_info == .pointer);
    try expect(ptr_info.pointer.size == .many);
    try expect(ptr_info.pointer.is_const == false);
    try expect(ptr_info.pointer.is_volatile == false);
    try expect(ptr_info.pointer.sentinel().? == 0);

    try expect(@typeInfo([:0]u8).pointer.sentinel() != null);
}

test "type info: slice type info" {
    try testSlice();
    try comptime testSlice();
}

fn testSlice() !void {
    const u32_slice_info = @typeInfo([]u32);
    try expect(u32_slice_info == .pointer);
    try expect(u32_slice_info.pointer.size == .slice);
    try expect(u32_slice_info.pointer.is_const == false);
    try expect(u32_slice_info.pointer.is_volatile == false);
    try expect(u32_slice_info.pointer.alignment == 4);
    try expect(u32_slice_info.pointer.child == u32);
}

test "type info: array type info" {
    try testArray();
    try comptime testArray();
}

fn testArray() !void {
    {
        const info = @typeInfo([42]u8);
        try expect(info == .array);
        try expect(info.array.len == 42);
        try expect(info.array.child == u8);
        try expect(info.array.sentinel() == null);
    }

    {
        const info = @typeInfo([10:0]u8);
        try expect(info.array.len == 10);
        try expect(info.array.child == u8);
        try expect(info.array.sentinel().? == @as(u8, 0));
        try expect(@sizeOf([10:0]u8) == info.array.len + 1);
    }
}

test "type info: error set, error union info, anyerror" {
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    try testErrorSet();
    try comptime testErrorSet();
}

fn testErrorSet() !void {
    const TestErrorSet = error{
        First,
        Second,
        Third,
    };

    const error_set_info = @typeInfo(TestErrorSet);
    try expect(error_set_info == .error_set);
    try expect(error_set_info.error_set.?.len == 3);
    try expect(mem.eql(u8, error_set_info.error_set.?[0].name, "First"));

    const error_union_info = @typeInfo(TestErrorSet!usize);
    try expect(error_union_info == .error_union);
    try expect(error_union_info.error_union.error_set == TestErrorSet);
    try expect(error_union_info.error_union.payload == usize);

    const global_info = @typeInfo(anyerror);
    try expect(global_info == .error_set);
    try expect(global_info.error_set == null);
}

test "type info: error set single value" {
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    const TestSet = error.One;

    const error_set_info = @typeInfo(@TypeOf(TestSet));
    try expect(error_set_info == .error_set);
    try expect(error_set_info.error_set.?.len == 1);
    try expect(mem.eql(u8, error_set_info.error_set.?[0].name, "One"));
}

test "type info: error set merged" {
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    const TestSet = error{ One, Two } || error{Three};

    const error_set_info = @typeInfo(TestSet);
    try expect(error_set_info == .error_set);
    try expect(error_set_info.error_set.?.len == 3);
    try expect(mem.eql(u8, error_set_info.error_set.?[0].name, "One"));
    try expect(mem.eql(u8, error_set_info.error_set.?[1].name, "Two"));
    try expect(mem.eql(u8, error_set_info.error_set.?[2].name, "Three"));
}

test "type info: enum info" {
    if (builtin.zig_backend == .stage2_arm) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    try testEnum();
    try comptime testEnum();
}

fn testEnum() !void {
    const Os = enum {
        Windows,
        Macos,
        Linux,
        FreeBSD,
    };

    const os_info = @typeInfo(Os);
    try expect(os_info == .@"enum");
    try expect(os_info.@"enum".fields.len == 4);
    try expect(mem.eql(u8, os_info.@"enum".fields[1].name, "Macos"));
    try expect(os_info.@"enum".fields[3].value == 3);
    try expect(os_info.@"enum".tag_type == u2);
    try expect(os_info.@"enum".decls.len == 0);
}

test "type info: union info" {
    try testUnion();
    try comptime testUnion();
}

fn testUnion() !void {
    const typeinfo_info = @typeInfo(Type);
    try expect(typeinfo_info == .@"union");
    try expect(typeinfo_info.@"union".layout == .auto);
    try expect(typeinfo_info.@"union".tag_type.? == TypeId);
    try expect(typeinfo_info.@"union".fields.len == 24);
    try expect(typeinfo_info.@"union".fields[4].type == @TypeOf(@typeInfo(u8).int));
    try expect(typeinfo_info.@"union".decls.len == 21);

    const TestNoTagUnion = union {
        Foo: void,
        Bar: u32,
    };

    const notag_union_info = @typeInfo(TestNoTagUnion);
    try expect(notag_union_info == .@"union");
    try expect(notag_union_info.@"union".tag_type == null);
    try expect(notag_union_info.@"union".layout == .auto);
    try expect(notag_union_info.@"union".fields.len == 2);
    try expect(notag_union_info.@"union".fields[0].alignment == @alignOf(void));
    try expect(notag_union_info.@"union".fields[1].type == u32);
    try expect(notag_union_info.@"union".fields[1].alignment == @alignOf(u32));

    const TestExternUnion = extern union {
        foo: *anyopaque,
    };

    const extern_union_info = @typeInfo(TestExternUnion);
    try expect(extern_union_info.@"union".layout == .@"extern");
    try expect(extern_union_info.@"union".tag_type == null);
    try expect(extern_union_info.@"union".fields[0].type == *anyopaque);
}

test "type info: struct info" {
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    try testStruct();
    try comptime testStruct();
}

fn testStruct() !void {
    const unpacked_struct_info = @typeInfo(TestStruct);
    try expect(unpacked_struct_info.@"struct".is_tuple == false);
    try expect(unpacked_struct_info.@"struct".backing_integer == null);
    try expect(unpacked_struct_info.@"struct".fields[0].alignment == @alignOf(u32));
    try expect(unpacked_struct_info.@"struct".fields[0].defaultValue().? == 4);
    try expect(mem.eql(u8, "foobar", unpacked_struct_info.@"struct".fields[1].defaultValue().?));
}

const TestStruct = struct {
    fieldA: u32 = 4,
    fieldB: *const [6:0]u8 = "foobar",
};

test "type info: packed struct info" {
    try testPackedStruct();
    try comptime testPackedStruct();
}

fn testPackedStruct() !void {
    const struct_info = @typeInfo(TestPackedStruct);
    try expect(struct_info == .@"struct");
    try expect(struct_info.@"struct".is_tuple == false);
    try expect(struct_info.@"struct".layout == .@"packed");
    try expect(struct_info.@"struct".backing_integer == u128);
    try expect(struct_info.@"struct".fields.len == 4);
    try expect(struct_info.@"struct".fields[0].alignment == 0);
    try expect(struct_info.@"struct".fields[2].type == f32);
    try expect(struct_info.@"struct".fields[2].defaultValue() == null);
    try expect(struct_info.@"struct".fields[3].defaultValue().? == 4);
    try expect(struct_info.@"struct".fields[3].alignment == 0);
    try expect(struct_info.@"struct".decls.len == 1);
}

const TestPackedStruct = packed struct {
    fieldA: u64,
    fieldB: void,
    fieldC: f32,
    fieldD: u32 = 4,

    pub fn foo(self: *const Self) void {
        _ = self;
    }
    const Self = @This();
};

test "type info: opaque info" {
    try testOpaque();
    try comptime testOpaque();
}

fn testOpaque() !void {
    const Foo = opaque {
        pub const A = 1;
        pub fn b() void {}
    };

    const foo_info = @typeInfo(Foo);
    try expect(foo_info.@"opaque".decls.len == 2);
}

test "type info: function type info" {
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;
    if (builtin.zig_backend == .stage2_riscv64) return error.SkipZigTest;

    try testFunction();
    try comptime testFunction();
}

fn testFunction() !void {
    if (builtin.zig_backend == .stage2_aarch64) return error.SkipZigTest;

    const S = struct {
        export fn typeInfoFoo() callconv(.c) usize {
            unreachable;
        }
        export fn typeInfoFooAligned() callconv(.c) usize {
            unreachable;
        }
    };
    _ = S;
    const foo_fn_type = @TypeOf(typeInfoFoo);
    const foo_fn_info = @typeInfo(foo_fn_type);
    try expect(foo_fn_info.@"fn".calling_convention.eql(.c));
    try expect(!foo_fn_info.@"fn".is_generic);
    try expect(foo_fn_info.@"fn".params.len == 2);
    try expect(foo_fn_info.@"fn".is_var_args);
    try expect(foo_fn_info.@"fn".return_type.? == usize);
    const foo_ptr_fn_info = @typeInfo(@TypeOf(&typeInfoFoo));
    try expect(foo_ptr_fn_info.pointer.size == .one);
    try expect(foo_ptr_fn_info.pointer.is_const);
    try expect(!foo_ptr_fn_info.pointer.is_volatile);
    try expect(foo_ptr_fn_info.pointer.address_space == .generic);
    try expect(foo_ptr_fn_info.pointer.child == foo_fn_type);
    try expect(!foo_ptr_fn_info.pointer.is_allowzero);
    try expect(foo_ptr_fn_info.pointer.sentinel() == null);

    // Avoid looking at `typeInfoFooAligned` on targets which don't support function alignment.
    switch (builtin.target.cpu.arch) {
        .spirv32,
        .spirv64,
        .wasm32,
        .wasm64,
        => return,
        else => {},
    }

    const aligned_foo_fn_type = @TypeOf(typeInfoFooAligned);
    const aligned_foo_fn_info = @typeInfo(aligned_foo_fn_type);
    try expect(aligned_foo_fn_info.@"fn".calling_convention.eql(.c));
    try expect(!aligned_foo_fn_info.@"fn".is_generic);
    try expect(aligned_foo_fn_info.@"fn".params.len == 2);
    try expect(aligned_foo_fn_info.@"fn".is_var_args);
    try expect(aligned_foo_fn_info.@"fn".return_type.? == usize);
    const aligned_foo_ptr_fn_info = @typeInfo(@TypeOf(&typeInfoFooAligned));
    try expect(aligned_foo_ptr_fn_info.pointer.size == .one);
    try expect(aligned_foo_ptr_fn_info.pointer.is_const);
    try expect(!aligned_foo_ptr_fn_info.pointer.is_volatile);
    try expect(aligned_foo_ptr_fn_info.pointer.alignment == 4);
    try expect(aligned_foo_ptr_fn_info.pointer.address_space == .generic);
    try expect(aligned_foo_ptr_fn_info.pointer.child == aligned_foo_fn_type);
    try expect(!aligned_foo_ptr_fn_info.pointer.is_allowzero);
    try expect(aligned_foo_ptr_fn_info.pointer.sentinel() == null);
}

extern fn typeInfoFoo(a: usize, b: bool, ...) callconv(.c) usize;
extern fn typeInfoFooAligned(a: usize, b: bool, ...) align(4) callconv(.c) usize;

test "type info: generic function types" {
    const G1 = @typeInfo(@TypeOf(generic1));
    try expect(G1.@"fn".params.len == 1);
    try expect(G1.@"fn".params[0].is_generic == true);
    try expect(G1.@"fn".params[0].type == null);
    try expect(G1.@"fn".return_type == void);

    const G2 = @typeInfo(@TypeOf(generic2));
    try expect(G2.@"fn".params.len == 3);
    try expect(G2.@"fn".params[0].is_generic == false);
    try expect(G2.@"fn".params[0].type == type);
    try expect(G2.@"fn".params[1].is_generic == true);
    try expect(G2.@"fn".params[1].type == null);
    try expect(G2.@"fn".params[2].is_generic == false);
    try expect(G2.@"fn".params[2].type == u8);
    try expect(G2.@"fn".return_type == void);

    const G3 = @typeInfo(@TypeOf(generic3));
    try expect(G3.@"fn".params.len == 1);
    try expect(G3.@"fn".params[0].is_generic == true);
    try expect(G3.@"fn".params[0].type == null);
    try expect(G3.@"fn".return_type == null);

    const G4 = @typeInfo(@TypeOf(generic4));
    try expect(G4.@"fn".params.len == 1);
    try expect(G4.@"fn".params[0].is_generic == true);
    try expect(G4.@"fn".params[0].type == null);
    try expect(G4.@"fn".return_type == null);
}

fn generic1(param: anytype) void {
    _ = param;
}
fn generic2(comptime T: type, param: T, param2: u8) void {
    _ = param;
    _ = param2;
}
fn generic3(param: anytype) @TypeOf(param) {}
fn generic4(comptime param: anytype) @TypeOf(param) {}

test "typeInfo with comptime parameter in struct fn def" {
    const S = struct {
        pub fn func(comptime x: f32) void {
            _ = x;
        }
    };
    comptime var info = @typeInfo(S);
    _ = &info;
}

test "type info: vectors" {
    try testVector();
    try comptime testVector();
}

fn testVector() !void {
    const vec_info = @typeInfo(@Vector(4, i32));
    try expect(vec_info == .vector);
    try expect(vec_info.vector.len == 4);
    try expect(vec_info.vector.child == i32);
}

test "type info: anyframe and anyframe->T" {
    if (true) {
        // https://github.com/ziglang/zig/issues/6025
        return error.SkipZigTest;
    }

    try testAnyFrame();
    try comptime testAnyFrame();
}

fn testAnyFrame() !void {
    {
        const anyframe_info = @typeInfo(anyframe->i32);
        try expect(anyframe_info == .@"anyframe");
        try expect(anyframe_info.@"anyframe".child.? == i32);
    }

    {
        const anyframe_info = @typeInfo(anyframe);
        try expect(anyframe_info == .@"anyframe");
        try expect(anyframe_info.@"anyframe".child == null);
    }
}

test "type info: pass to function" {
    _ = passTypeInfo(@typeInfo(void));
    _ = comptime passTypeInfo(@typeInfo(void));
}

fn passTypeInfo(comptime info: Type) type {
    _ = info;
    return void;
}

test "type info: TypeId -> Type impl cast" {
    _ = passTypeInfo(TypeId.void);
    _ = comptime passTypeInfo(TypeId.void);
}

test "sentinel of opaque pointer type" {
    const c_void_info = @typeInfo(*anyopaque);
    try expect(c_void_info.pointer.sentinel_ptr == null);
}

test "@typeInfo does not force declarations into existence" {
    const S = struct {
        x: i32,

        fn doNotReferenceMe() void {
            @compileError("test failed");
        }
    };
    comptime assert(@typeInfo(S).@"struct".fields.len == 1);
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "Declarations are returned in declaration order" {
    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    const S = struct {
        pub const a = 1;
        pub const b = 2;
        pub const c = 3;
        pub const d = 4;
        pub const e = 5;
    };
    const d = @typeInfo(S).@"struct".decls;
    try expect(std.mem.eql(u8, d[0].name, "a"));
    try expect(std.mem.eql(u8, d[1].name, "b"));
    try expect(std.mem.eql(u8, d[2].name, "c"));
    try expect(std.mem.eql(u8, d[3].name, "d"));
    try expect(std.mem.eql(u8, d[4].name, "e"));
}

test "Struct.is_tuple for anon list literal" {
    try expect(@typeInfo(@TypeOf(.{0})).@"struct".is_tuple);
}

test "Struct.is_tuple for anon struct literal" {
    if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest;

    if (builtin.zig_backend == .stage2_sparc64) return error.SkipZigTest; // TODO

    const info = @typeInfo(@TypeOf(.{ .a = 0 }));
    try expect(!info.@"struct".is_tuple);
    try expect(std.mem.eql(u8, info.@"struct".fields[0].name, "a"));
}

test "StructField.is_comptime" {
    const info = @typeInfo(struct { x: u8 = 3, comptime y: u32 = 5 }).@"struct";
    try expect(!info.fields[0].is_comptime);
    try expect(info.fields[1].is_comptime);
}

test "value from struct @typeInfo default_value_ptr can be loaded at comptime" {
    comptime {
        const a = @typeInfo(@TypeOf(.{ .foo = @as(u8, 1) })).@"struct".fields[0].default_value_ptr;
        try expect(@as(*const u8, @ptrCast(a)).* == 1);
    }
}

test "type info of tuple of string literal default value" {
    const struct_field = @typeInfo(@TypeOf(.{"hi"})).@"struct".fields[0];
    const value = struct_field.defaultValue().?;
    comptime std.debug.assert(value[0] == 'h');
}

test "@typeInfo function with generic return type and inferred error set" {
    const S = struct {
        fn testFn(comptime T: type) !T {}
    };

    const ret_ty = @typeInfo(@TypeOf(S.testFn)).@"fn".return_type;
    comptime assert(ret_ty == null);
}
