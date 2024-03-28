const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const constants = @import("constants.zig");

const AnimationIndex = sprite.SpriteSheetUniform.Index.Animated;

pub const PlusEffect = struct {
    active: bool,
    animIndex: AnimationIndex,
    position: rl.Vector2,
};

pub const BonusEffect = struct {
    const Self = @This();

    plusSpriteSheet: sprite.SpriteSheetUniform,
    plus: []PlusEffect,
    allocator: std.mem.Allocator,

    count: i32, // active count

    pub fn init(allocator: std.mem.Allocator) !Self {
        var plus = try allocator.alloc(PlusEffect, 500);
        errdefer allocator.free(plus);
        for (plus) |i| {
            i.active = false;
        }

        var plusSpriteSheet = sprite.SpriteSheetUniform.initFromFile(constants.TEXTURE_DIR ++ "PL.png", 1, 18);
        errdefer plusSpriteSheet.unload();

        return Self{
            .plusSpriteSheet = undefined,
            .plus = plus,
            .allocator = allocator,
            .count = 0,
        };
    }

    pub fn spawn(self: *Self, applePos: rl.Vector2) void {
        _ = applePos;
        _ = self;
    }

    fn nextUnused(self: Self) *PlusEffect {
        for (self.plus) |*i| {
            if (!i.active) {
                return i;
            }
        }
        @panic("Expect to always have room for the next bonus animation");
    }

    pub fn unload(self: *Self) void {
        self.allocator.free(self.plus);
    }
};
