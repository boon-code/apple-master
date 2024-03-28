const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const constants = @import("constants.zig");

const AnimationIndex = sprite.SpriteSheetUniform.Index.Animated;

pub const PlusEffect = struct {
    const Self = @This();

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
        for (plus) |*i| {
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

    pub fn spawn(self: *Self, applePos: rl.Vector2, time: f64) void {
        var next = self.nextUnused();
        next.position = applePos;
        next.animIndex = self.plusSpriteSheet.createIndex(0, 0).createAnimated(constants.PLUS_ANIM_SPEED);
        next.animIndex.reset(time + constants.PLUS_WAIT_FIRST);
        next.active = true;
        self.count += 1;
    }

    pub fn drawAndUpdate(self: *Self, time: f64) void {
        var num = self.count;
        if (num <= 0) {
            return;
        }
        for (self.plus) |*plus| {
            if (plus.active) {
                const wrapped = plus.animIndex.update(time);
                if (wrapped) {
                    self.count -= 1;
                    plus.active = false;
                } else {
                    const pos1 = rl.Vector2.init(plus.position.x + constants.APPLE_OFFSET_X, plus.position.y);
                    const pos2 = rl.Vector2.init(pos1.x + constants.PLUS_WIDTH + 2.0, plus.position.y);
                    self.plusSpriteSheet.draw(pos1, plus.animIndex.index, .normal);
                    self.plusSpriteSheet.draw(pos2, plus.animIndex.index, .normal);
                }

                num -= 1;
                if (num <= 0) {
                    return;
                }
            }
        }
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
        self.plusSpriteSheet.unload();
    }
};
