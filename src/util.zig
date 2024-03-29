// Utilities
const std = @import("std");
const rl = @import("raylib");

// BUG: rl.GetRandomValue seems to be limited to 2**31 - 1 in this case
const I32_MIN = 0;
const I32_MAX = std.math.maxInt(i32) - 1;

pub fn f32FromInt(v: anytype) f32 {
    return @as(f32, @floatFromInt(v));
}

pub fn getExtension(path: [:0]const u8) ?[:0]const u8 {
    var i = path.len;
    while (i > 0) {
        i -= 1;
        switch (path[i]) {
            '.' => return path[i.. :0],
            '/' => return null,
            else => {},
        }
    }
    return null;
}

pub fn getRandom(comptime T: type, min: T, max: T) T {
    return getRandomInner(T, getRandomI32FullRange(), min, max);
}

inline fn getRandomI32FullRange() i32 {
    return rl.getRandomValue(I32_MIN, I32_MAX);
}

inline fn getRandomInner(comptime T: type, randInt: i32, min: T, max: T) T {
    //const range: T = @as(T, @floatFromInt(I32_MAX)) - @as(T, @floatFromInt(I32_MIN));
    // BUG: see getRandomI32FullRange
    const range: T = @as(T, @floatFromInt(I32_MAX)) - @as(T, @floatFromInt(I32_MIN));
    const prop: T = @as(T, @floatFromInt(randInt)) / range;
    return min + (max - min) * prop;
}
