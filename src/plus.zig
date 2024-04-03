const std = @import("std");
const rl = @import("raylib");
const sprite = @import("sprite.zig");
const constants = @import("constants.zig");

const AnimationIndex = sprite.SpriteSheetUniform.Index.Animated;

pub const PlusEffect = struct {
    const Self = @This();

    active: bool,
    anim_index: AnimationIndex,
    position: rl.Vector2,
};

pub const BonusEffect = struct {
    const Self = @This();

    sprite_sheet: sprite.SpriteSheetUniform,
    plus: []PlusEffect,
    allocator: std.mem.Allocator,

    count: i32, // active count

    pub fn init(allocator: std.mem.Allocator) !Self {
        var plus = try allocator.alloc(PlusEffect, 30);
        errdefer allocator.free(plus);
        for (plus) |*i| {
            i.active = false;
        }

        var sprite_sheet = sprite.SpriteSheetUniform.initFromEmbeddedFile(
            constants.texture_dir ++ "PL2.png",
            1,
            constants.plus_anim_count,
            constants.plus_width * constants.plus_anim_count,
            constants.plus_height,
        );
        errdefer sprite_sheet.unload();

        return Self{
            .sprite_sheet = sprite_sheet,
            .plus = plus,
            .allocator = allocator,
            .count = 0,
        };
    }

    pub fn spawn(self: *Self, applePos: rl.Vector2, time: f64) void {
        var next = self.nextUnused();
        next.position = applePos;
        next.anim_index = self.sprite_sheet.createIndex(0, 0).createAnimated(constants.plus_anim_speed, time);
        next.anim_index.reset(time + constants.plus_wait_first);
        next.active = true;
        self.count += 1;
        std.debug.print("Spawned a plus effect: count={d}\n", .{self.count});
    }

    pub fn drawAndUpdate(self: *Self, time: f64) void {
        var num = self.count;
        for (self.plus) |*plus| {
            if (num <= 0) {
                return;
            }
            if (plus.active) {
                num -= 1;
                const wrapped = plus.anim_index.update(time);
                if (wrapped) {
                    self.count -= 1;
                    plus.active = false;
                } else {
                    const y = plus.position.y + constants.plus_offset_y;
                    const pos1 = rl.Vector2.init(plus.position.x + constants.apple_offset_x, y);
                    const x2 = plus.position.x + constants.apple_width - constants.apple_offset_x - constants.plus_width;
                    const pos2 = rl.Vector2.init(x2, y);
                    self.sprite_sheet.draw(pos1, plus.anim_index.index, .normal);
                    self.sprite_sheet.draw(pos2, plus.anim_index.index, .normal);
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
        self.sprite_sheet.unload();
    }
};
