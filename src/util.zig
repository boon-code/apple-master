// Utilities
const std = @import("std");
const rl = @import("raylib");

pub fn f32FromInt(v: anytype) f32 {
    return @as(f32, @floatFromInt(v));
}

pub fn getRandom(comptime T: type, min: T, max: T) T {
    const mi = std.math.minInt(i32);
    const ma = std.math.maxInt(i32);
    const intValue = rl.getRandomValue(std.math.minInt(i32), std.math.maxInt(i32));

    const prop: T = @as(T, @floatFromInt(intValue)) / @as(T, @floatFromInt(ma - mi));
    return min + (max - min) * prop;
}
