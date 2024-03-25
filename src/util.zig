// Utilities

pub fn f32FromInt(v: anytype) f32 {
    return @as(f32, @floatFromInt(v));
}
